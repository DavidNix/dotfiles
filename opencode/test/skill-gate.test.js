import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import skillGate, { hiddenSkillIDs } from '../plugins/skill-gate.js';

const MARKETING = 'coreyhaines31/marketingskills';

const lock = {
  skills: {
    'ab-testing': { source: MARKETING, skillPath: 'skills/ab-testing/SKILL.md' },
    'Cold Email': { source: MARKETING, skillPath: 'skills/cold-email/SKILL.md' },
    copywriting: { source: MARKETING, skillPath: 'skills/copywriting/SKILL.md' },
    'root-skill': { source: MARKETING, skillPath: 'SKILL.md' },
    pdf: { source: 'anthropics/skills', skillPath: 'skills/pdf/SKILL.md' },
    'skill-creator': { source: 'anthropics/skills', skillPath: 'skills/skill-creator/SKILL.md' },
    'hook-writer': { source: 'DavidNix/nixpowers', skillPath: 'skills/hook-writer/SKILL.md' },
  },
};

function withLock(t, contents, synced = []) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'skill-gate.'));
  if (contents !== undefined) {
    fs.mkdirSync(path.join(home, '.agents'));
    fs.writeFileSync(path.join(home, '.agents', '.skill-lock.json'), contents);
  }
  const account = path.join(home, '.claude', 'skills', 'synced', 'org_account');
  for (const id of synced) {
    fs.mkdirSync(path.join(account, id), { recursive: true });
    fs.writeFileSync(path.join(account, id, 'SKILL.md'), `---\nname: ${id}\n---\n`);
  }
  const previous = process.env.HOME;
  process.env.HOME = home;
  t.after(() => {
    process.env.HOME = previous;
    fs.rmSync(home, { recursive: true, force: true });
  });
}

const LISTED = ['apple-design', 'ask-sonner', 'docx', 'frontend-slides', 'pdf', 'pptx', 'upgrade-stripe', 'write-swift', 'xlsx'];

function catalog() {
  return Object.fromEntries(['ab-testing', 'cold-email', 'copywriting', 'root-skill', 'hook-writer', 'skill-creator', 'morning', 'no-skill', ...LISTED]
    .map(id => [id, { id, description: id }]));
}

function apply(transform, skills) {
  transform({ update: (id, update) => { if (skills[id]) update(skills[id]); } });
  return Object.keys(skills).filter(id => skills[id].autoinvoke === false).sort();
}

const HIDDEN = ['ab-testing', 'cold-email', 'hook-writer', 'root-skill', ...LISTED].sort();

test('hides listed skills and pack skills by directory ID except advertised ones', () => {
  assert.deepEqual([...hiddenSkillIDs(lock)].sort(), HIDDEN);
  assert.deepEqual([...hiddenSkillIDs(undefined)].sort(), LISTED);
  assert.deepEqual([...hiddenSkillIDs(undefined, ['morning', 'cro'])].sort(), [...LISTED, 'morning'].sort());
});

test('hides every skill synced from claude.ai except advertised ones', async t => {
  withLock(t, undefined, ['morning', 'copywriting']);
  fs.mkdirSync(path.join(process.env.HOME, '.claude', 'skills', 'synced', 'org_account', 'no-skill'));
  const transforms = [];
  await skillGate.setup({
    skill: { transform: async callback => { transforms.push(callback); } },
    plugin: { list: async () => ({ data: [{ id: 'opencode.config.skill', state: { status: 'active' } }] }) },
  });
  assert.deepEqual(apply(transforms[0], catalog()), [...LISTED, 'morning'].sort());
});

test('marks hidden skills as not auto-invoked once skills are configured', async t => {
  withLock(t, JSON.stringify(lock));
  const transforms = [];
  const cleanup = await skillGate.setup({
    skill: { transform: async callback => {
      transforms.push(callback);
      return { dispose: async () => {} };
    } },
    plugin: { list: async () => ({ data: [{ id: 'opencode.config.skill', state: { status: 'active' } }] }) },
  });
  assert.equal(cleanup, undefined);
  assert.equal(transforms.length, 1);
  assert.deepEqual(apply(transforms[0], catalog()), HIDDEN);
});

test('still hides individually listed skills without a readable skills lock', async t => {
  withLock(t, '{not json');
  const transforms = [];
  await skillGate.setup({
    skill: { transform: async callback => { transforms.push(callback); } },
    plugin: { list: async () => ({ data: [{ id: 'opencode.config.skill', state: { status: 'active' } }] }) },
  });
  assert.deepEqual(apply(transforms[0], catalog()), LISTED);
});

test('re-registers after the built-in skill loader becomes active', { timeout: 2000 }, async t => {
  withLock(t, JSON.stringify(lock));
  const transforms = [];
  let status;
  let disposed = 0;
  const cleanup = await skillGate.setup({
    skill: { transform: async callback => {
      transforms.push(callback);
      return { dispose: async () => { disposed++; } };
    } },
    plugin: { list: async () => ({ data: status ? [{ id: 'opencode.config.skill', state: { status } }] : [] }) },
    event: { subscribe: async function* () {
      yield { type: 'server.connected' };
      status = 'active';
      yield { type: 'plugin.updated' };
    } },
  });
  t.after(() => cleanup?.());
  for (let i = 0; i < 50 && transforms.length < 2; i++) await new Promise(resolve => setTimeout(resolve, 10));
  assert.equal(transforms.length, 2);
  assert.equal(disposed, 1);
  assert.deepEqual(apply(transforms[1], catalog()), HIDDEN);
});
