import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Every advertised skill adds its description to each model request. Hidden
// skills stay loadable by mentioning them as @skill-id.
const HIDDEN_SKILLS = [
  'apple-design', 'ask-sonner', 'docx', 'frontend-slides', 'pdf', 'pptx', 'upgrade-stripe', 'write-swift', 'xlsx',
];
const HIDDEN_SOURCES = ['DavidNix/nixpowers', 'coreyhaines31/marketingskills'];
// Exceptions to the hidden sources and synced claude.ai skills.
const ADVERTISED = new Set(['copy-editing', 'copywriting', 'cro', 'marketing-psychology']);

// The skills CLI keys its lock by skill name; OpenCode IDs skills by directory.
const sourceSkillIDs = (lock) => Object.entries(lock?.skills ?? {})
  .filter(([, skill]) => HIDDEN_SOURCES.includes(skill?.source))
  .map(([name, skill]) => {
    const directory = skill.skillPath ? path.basename(path.dirname(skill.skillPath)) : '';
    return directory && directory !== '.' ? directory : name;
  });

export const hiddenSkillIDs = (lock, synced = []) => new Set([
  ...HIDDEN_SKILLS,
  ...[...sourceSkillIDs(lock), ...synced].filter(id => !ADVERTISED.has(id)),
]);

const readLock = () => {
  try {
    return JSON.parse(fs.readFileSync(path.join(os.homedir(), '.agents', '.skill-lock.json'), 'utf8'));
  } catch {
    return undefined;
  }
};

const directories = (directory) => {
  try {
    return fs.readdirSync(directory, { withFileTypes: true }).filter(entry => entry.isDirectory()).map(entry => entry.name);
  } catch {
    return [];
  }
};

// Claude Code syncs claude.ai account skills to synced/<account>/<skill>/, and
// OpenCode also discovers skills under ~/.claude/skills.
const readSyncedSkillIDs = () => {
  const root = path.join(os.homedir(), '.claude', 'skills', 'synced');
  return directories(root).flatMap(account => directories(path.join(root, account))
    .filter(id => fs.existsSync(path.join(root, account, id, 'SKILL.md'))));
};

export default {
  id: 'dotfiles.skill-gate',
  async setup(ctx) {
    const hidden = hiddenSkillIDs(readLock(), readSyncedSkillIDs());
    const transform = (editor) => {
      for (const id of hidden) editor.update(id, (skill) => { skill.autoinvoke = false; });
    };
    let registration = await ctx.skill.transform(transform);
    // Discovered skills come from a built-in that loads after external plugins,
    // and updates to missing IDs are ignored, so re-register once it loads.
    const configStatus = async () => (await ctx.plugin.list()).data
      .find(plugin => plugin.id === 'opencode.config.skill')?.state.status;
    if (await configStatus()) return;

    const controller = new AbortController();
    const observe = async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (!['server.connected', 'plugin.updated'].includes(event.type)) continue;
        const status = await configStatus();
        if (!status) continue;
        if (status === 'active') {
          await registration.dispose();
          registration = await ctx.skill.transform(transform);
        }
        break;
      }
    };
    void observe().catch(error => {
      if (!controller.signal.aborted) console.error('Skill gate:', error);
    });
    return () => controller.abort();
  },
};
