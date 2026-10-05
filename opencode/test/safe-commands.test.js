import assert from "node:assert/strict";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  SafeCommandsPlugin,
  isGitPushCommand,
  isUnsafeGoCommand,
  validateSafeCommand,
} from "../plugins/safe-commands.js";

const allowedCommands = [
  "git status",
  "git diff",
  "rg \"git push\"",
  "go get example.com/module@latest",
  "go generate ./...",
  "go clean -modcache",
  "go mod tidy",
  "go work sync",
  "go test ./...",
  "go build ./...",
  "go vet ./...",
  "go list ./...",
  "go env",
  "go run .",
  "rg \"go run\"",
  "cargo build --workspace",
  "cargo check --all-targets",
  "cargo clippy --all-targets --all-features -- -D warnings",
  "cargo fmt --all -- --check",
  "cargo test --all-features",
  "cargo run --bin app",
  "cargo clean",
  "cargo add serde",
  "cargo update",
  "cargo doc --no-deps",
  "rustc --version",
  "rustfmt --check src/lib.rs",
  "rustdoc --test src/lib.rs",
  "clippy-driver --version",
];

const blockedCommands = [
  ["git push", /git push commands are blocked/],
  ["git push origin feature", /git push commands are blocked/],
  ["terraform apply -auto-approve", /terraform apply commands are blocked/],
  ["tofu apply -auto-approve", /tofu apply commands are blocked/],
  ["cd infra && tofu apply", /tofu apply commands are blocked/],
  ["go install example.com/tool@latest", /go install is blocked/],
  ["go env -w GOPROXY=direct", /go env -w\/-u is blocked/],
  ["go env -u GOPROXY", /go env -w\/-u is blocked/],
  ["go test -exec ./wrapper ./...", /go test -exec is blocked/],
  ["go test -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go build -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go vet -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go list -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go vet -vettool ./vettool ./...", /go vet -vettool is blocked/],
  ["cargo install cargo-edit", /cargo install\/uninstall is blocked/],
  ["cargo uninstall cargo-edit", /cargo install\/uninstall is blocked/],
  ["cargo login token", /cargo login\/logout is blocked/],
  ["cargo logout", /cargo login\/logout is blocked/],
  ["cargo owner --add user crate", /cargo owner is blocked/],
  ["cargo publish", /cargo publish is blocked/],
  ["cargo +nightly publish", /cargo publish is blocked/],
  ["cargo yank --version 1.0.0 crate", /cargo yank is blocked/],
];

test("isGitPushCommand only matches actual git push invocations", () => {
  assert.equal(isGitPushCommand("git push"), true);
  assert.equal(isGitPushCommand("cd repo && git push origin feature"), true);
  assert.equal(isGitPushCommand("rg \"git push\""), false);
});

test("isUnsafeGoCommand only matches unsafe go invocations", () => {
  assert.equal(isUnsafeGoCommand("go run ."), false);
  assert.equal(isUnsafeGoCommand("go test -exec ./wrapper ./..."), true);
  assert.equal(isUnsafeGoCommand("go get example.com/module@latest"), false);
  assert.equal(isUnsafeGoCommand("rg \"go run\""), false);
});

test("validateSafeCommand allows safe commands", () => {
  for (const command of allowedCommands) {
    assert.doesNotThrow(() => validateSafeCommand(command), command);
  }
});

test("validateSafeCommand blocks unsafe commands", () => {
  for (const [command, expectedMessage] of blockedCommands) {
    assert.throws(() => validateSafeCommand(command), expectedMessage, command);
  }
});

async function hooks() {
  const registered = {};
  await SafeCommandsPlugin.setup({
    permission: { hook: async (name, callback) => { registered[`permission.${name}`] = callback; } },
    shell: { hook: async (name, callback) => { registered[`shell.${name}`] = callback; } },
  });
  return registered;
}

test("V2 permission hook denies dangerous shell commands with the reason", async () => {
  const evaluate = (await hooks())["permission.evaluate"];
  assert.equal(typeof evaluate, "function");
  for (const command of allowedCommands) {
    const event = { action: "shell", resources: [command], effect: "allow" };
    evaluate(event);
    assert.equal(event.effect, "allow", command);
  }
  for (const [command, message] of blockedCommands) {
    const event = { action: "shell", resources: ["git status", command], effect: "allow" };
    evaluate(event);
    assert.equal(event.effect, "deny", command);
    assert.match(event.message, message, command);
  }
  const read = { action: "read", resources: ["git push"], effect: "allow" };
  evaluate(read);
  assert.equal(read.effect, "allow");
});

test("V2 shell hook blocks dangerous commands before a process is created", async () => {
  const beforeCreate = (await hooks())["shell.create.before"];
  assert.equal(typeof beforeCreate, "function");
  for (const command of allowedCommands) {
    assert.doesNotThrow(() => beforeCreate({ command }), command);
  }
  for (const [command, message] of blockedCommands) {
    assert.throws(() => beforeCreate({ command }), message, command);
  }
});

test("validateSafeCommand blocks OpenCode private data", () => {
  const dataDir = path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share"), "opencode");
  assert.throws(() => validateSafeCommand(`cat ${path.join(dataDir, "auth.json")}`), /OpenCode private data/);
  assert.throws(() => validateSafeCommand(`sqlite3 ${path.join(dataDir, "opencode.db")}`), /OpenCode private data/);
  assert.throws(() => validateSafeCommand(`rg token ${path.join(dataDir, "storage")}`), /OpenCode private data/);
  assert.doesNotThrow(() => validateSafeCommand(`cat ${path.join(dataDir, "tool-output", "result.txt")}`));
});
