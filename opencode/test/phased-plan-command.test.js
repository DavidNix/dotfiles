import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const command = readFileSync(new URL("../commands/phased-plan.md", import.meta.url), "utf8");

test("phased-plan accepts explicit modes for new artifacts", () => {
  assert.match(command, /\/phased-plan <file\|gh\|github>/);
  assert.match(command, /creation mode always creates a new artifact/i);
});

test("file creation mode writes a new repository plan", () => {
  assert.match(command, /plans\/<short-kebab-case-name>\.md/);
  assert.match(command, /first unused numeric suffix/i);
});

test("GitHub creation mode creates a new parent issue", () => {
  assert.match(command, /gh issue create --title "\$title" --body-file - <<'EOF'/);
  assert.match(command, /create the parent before its managed phase sub-issues/i);
});
