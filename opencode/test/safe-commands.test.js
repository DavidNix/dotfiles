import assert from "node:assert/strict";
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
];

const blockedCommands = [
  ["git push", /git push commands are blocked/],
  ["git push origin feature", /git push commands are blocked/],
  ["go install example.com/tool@latest", /go install is blocked/],
  ["go env -w GOPROXY=direct", /go env -w\/-u is blocked/],
  ["go env -u GOPROXY", /go env -w\/-u is blocked/],
  ["go test -exec ./wrapper ./...", /go test -exec is blocked/],
  ["go test -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go build -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go vet -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go list -toolexec ./wrapper ./...", /go -toolexec is blocked/],
  ["go vet -vettool ./vettool ./...", /go vet -vettool is blocked/],
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

test("plugin hook uses validateSafeCommand", async () => {
  const plugin = await SafeCommandsPlugin();
  const beforeExecute = plugin["tool.execute.before"];

  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, { args: { command: "go test ./..." } }));
  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, { args: { command: "go run ." } }));
  await assert.doesNotReject(() => beforeExecute({ tool: "read" }, { args: { command: "go run ." } }));
});

test("plugin hook tolerates missing or non-string command args", async () => {
  const plugin = await SafeCommandsPlugin();
  const beforeExecute = plugin["tool.execute.before"];

  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, { args: {} }));
  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, {}));
  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, { args: { command: { command: "go test ./..." } } }));
});

test("plugin hook inspects string-array command args", async () => {
  const plugin = await SafeCommandsPlugin();
  const beforeExecute = plugin["tool.execute.before"];

  await assert.doesNotReject(() => beforeExecute({ tool: "bash" }, { args: { command: ["go", "test", "./..."] } }));
  await assert.rejects(
    () => beforeExecute({ tool: "bash" }, { args: { command: ["git", "push"] } }),
    /git push commands are blocked/,
  );
});
