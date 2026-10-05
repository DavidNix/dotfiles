import assert from 'node:assert/strict';
import test from 'node:test';
import builder from '../plugins/builder.js';

async function override(agents, env) {
  const previous = { OC_ORCH: process.env.OC_ORCH, OC_PRIMARY: process.env.OC_PRIMARY, OC_SMALL: process.env.OC_SMALL };
  try {
    for (const name of Object.keys(previous)) {
      if (env[name] === undefined) delete process.env[name];
      else process.env[name] = env[name];
    }
    const transforms = [];
    await builder.setup?.({
      agent: { transform: async callback => transforms.push(callback) },
      plugin: { list: async () => ({ data: [{ id: 'opencode.config.agent', state: { status: 'active' } }] }) },
    });
    for (const transform of transforms) {
      transform({
        update: (name, update) => { if (agents[name]) update(agents[name]); },
      });
    }
    return agents;
  } finally {
    for (const [name, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[name];
      else process.env[name] = value;
    }
  }
}

const names = ['plan', 'build', 'prototype', 'builder', 'frontend-builder', 'explore', 'general', 'title', 'summary'];
const original = () => Object.fromEntries(names.map(name => [name, {
  model: { providerID: 'nixlab-large', id: 'nixlab/large1', variant: 'low' },
  permissions: [{ action: 'subagent', resource: '*', effect: 'deny' }],
}]));

test('primary override changes only primary agents and preserves their variant', async () => {
  const expected = original();
  for (const name of ['plan', 'build', 'prototype']) {
    expected[name].model = { providerID: 'fireworks-ai', id: 'accounts/fireworks/models/deepseek-v4p1-flash', variant: 'low' };
  }
  assert.deepEqual(await override(original(), {
    OC_PRIMARY: 'fireworks-ai/accounts/fireworks/models/deepseek-v4p1-flash',
  }), expected);
});

test('builder override changes only builder subagents and honors an explicit variant', async () => {
  const expected = original();
  for (const name of ['builder', 'frontend-builder', 'explore', 'general']) {
    expected[name].model = { providerID: 'openai', id: 'gpt-5.6-sol', variant: 'high' };
  }
  assert.deepEqual(await override(original(), { OC_ORCH: 'openai/gpt-5.6-sol#high' }), expected);
});

test('primary and builder overrides work together on the V2 agent catalog', async () => {
  const result = await override(original(), { OC_PRIMARY: 'openai/gpt-6-astra-fast', OC_ORCH: 'openai/gpt-5.6-sol' });
  assert.equal(result.plan.model.id, 'gpt-6-astra-fast');
  assert.equal(result.builder.model.id, 'gpt-5.6-sol');
  assert.deepEqual(result.summary, original().summary);
});

test('small override changes only title and summary', async () => {
  const expected = original();
  for (const name of ['title', 'summary']) {
    expected[name].model = { providerID: 'openai', id: 'gpt-6.1-sol-fast', variant: 'low' };
  }
  assert.deepEqual(await override(original(), { OC_SMALL: 'openai/gpt-6.1-sol-fast' }), expected);
});

test('inactive overrides leave agents unchanged', async () => {
  assert.deepEqual(await override(original(), {}), original());
});

test('overrides catch config activation that precedes the event subscription', async () => {
  const previous = process.env.OC_ORCH;
  process.env.OC_ORCH = 'openai/gpt-5.6-sol';
  const callbacks = [];
  let configured = false;
  let release;
  const ready = new Promise(resolve => { release = resolve; });
  let cleanup;
  let beforePrompt;
  try {
    cleanup = await builder.setup({
      agent: { transform: async callback => {
        callbacks.push(callback);
        return { dispose: async () => {} };
      } },
      plugin: { list: async () => ({ data: configured ? [{ id: 'opencode.config.agent', state: { status: 'active' } }] : [] }) },
      session: { hook: async (name, callback) => {
        assert.equal(name, 'prompt');
        beforePrompt = callback;
      } },
      event: { subscribe: async function* () {
        await ready;
        yield { type: 'server.connected' };
      } },
    });
    assert.equal(typeof beforePrompt, 'function');
    let admitted = false;
    const admission = beforePrompt().then(() => { admitted = true; });
    await new Promise(resolve => setTimeout(resolve, 0));
    assert.equal(admitted, false, 'first prompt waits for the authored config override');
    configured = true;
    release();
    await admission;
    assert.equal(callbacks.length, 2, 'model override is replayed after config registration');
    const agents = original();
    callbacks[1]({ update: (name, update) => update(agents[name]) });
    assert.equal(agents.builder.model.id, 'gpt-5.6-sol');
  } finally {
    cleanup?.();
    if (previous === undefined) delete process.env.OC_ORCH;
    else process.env.OC_ORCH = previous;
  }
});

test('invalid model selections are logged and skipped', async t => {
  const errors = t.mock.method(console, 'error', () => {});
  const expected = original();
  for (const name of ['plan', 'build', 'prototype']) {
    expected[name].model = { providerID: 'openai', id: 'gpt-6-astra-fast', variant: 'low' };
  }
  assert.deepEqual(await override(original(), { OC_ORCH: 'gpt-5.6-sol', OC_PRIMARY: 'openai/gpt-6-astra-fast' }), expected);
  assert.match(String(errors.mock.calls[0]?.arguments[0]), /invalid model gpt-5\.6-sol/);
});

async function pendingConfig(t, { status, subscribe }) {
  const previous = process.env.OC_ORCH;
  process.env.OC_ORCH = 'openai/gpt-5.6-sol';
  t.after(() => {
    if (previous === undefined) delete process.env.OC_ORCH;
    else process.env.OC_ORCH = previous;
  });
  const callbacks = [];
  let beforePrompt;
  const cleanup = await builder.setup({
    agent: { transform: async callback => {
      callbacks.push(callback);
      return { dispose: async () => {} };
    } },
    plugin: { list: async () => ({ data: status() ? [{ id: 'opencode.config.agent', state: { status: status() } }] : [] }) },
    session: { hook: async (_name, callback) => { beforePrompt = callback; } },
    event: { subscribe },
  });
  t.after(() => cleanup?.());
  return { callbacks, beforePrompt };
}

test('a failed agent config releases prompts without replaying overrides', { timeout: 2000 }, async t => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  let status;
  const { callbacks, beforePrompt } = await pendingConfig(t, {
    status: () => status,
    subscribe: async function* () {
      status = 'failed';
      yield { type: 'plugin.updated' };
    },
  });
  await beforePrompt();
  assert.equal(callbacks.length, 1);
});

test('prompts are released when the agent config never loads', { timeout: 2000 }, async t => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const errors = t.mock.method(console, 'error', () => {});
  const { beforePrompt } = await pendingConfig(t, {
    status: () => undefined,
    subscribe: async function* ({ signal }) {
      await new Promise(resolve => signal.addEventListener('abort', resolve));
    },
  });
  let admitted = false;
  const admission = beforePrompt().then(() => { admitted = true; });
  await Promise.resolve();
  assert.equal(admitted, false);
  t.mock.timers.tick(10_000);
  await admission;
  assert.match(String(errors.mock.calls[0]?.arguments[0]), /did not load/);
});
