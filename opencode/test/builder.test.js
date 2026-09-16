import assert from 'node:assert/strict';
import test from 'node:test';
import builder from '../plugins/builder.js';

test('flag overrides the builder, frontend-builder, explore and general subagent models', async () => {
  const previous = process.env.OC_ORCH;
  try {
    const original = {
      model: 'openai/gpt-6-astra-fast',
      agent: {
        build: { model: 'openai/gpt-6-astra-fast', variant: 'low' },
        explore: { model: 'nixlab-large/deepseek-ai/DeepSeek-V4-Flash-0731', variant: 'low' },
        general: { model: 'nixlab-large/deepseek-ai/DeepSeek-V4-Flash-0731', variant: 'low' },
        builder: { model: 'openai/gpt-6-astra-fast' },
        'frontend-builder': { model: 'openai/gpt-6-astra-fast' },
        summary: { model: 'openai/gpt-5.6-luna' },
        inherited: { mode: 'subagent' },
      },
      permission: { bash: 'ask' },
    };
    delete process.env.OC_ORCH;
    const inactive = structuredClone(original);
    await (await builder()).config?.(inactive);
    assert.deepEqual(inactive, original);

    process.env.OC_ORCH = 'openai/gpt-5.6-sol';
    const active = structuredClone(original);
    await (await builder()).config?.(active);
    const expected = structuredClone(original);
    for (const name of ['builder', 'frontend-builder', 'explore', 'general']) {
      expected.agent[name].model = 'openai/gpt-5.6-sol';
    }
    assert.deepEqual(active, expected);
  } finally {
    if (previous === undefined) delete process.env.OC_ORCH;
    else process.env.OC_ORCH = previous;
  }
});

test('flag creates missing builder subagent entries', async () => {
  const previous = process.env.OC_ORCH;
  try {
    process.env.OC_ORCH = 'openai/gpt-5.6-sol';
    const original = { agent: { build: { model: 'openai/gpt-6-astra-fast' } } };
    const clone = structuredClone(original);
    await (await builder()).config?.(clone);
    assert.deepEqual(clone, {
      agent: {
        build: { model: 'openai/gpt-6-astra-fast' },
        builder: { model: 'openai/gpt-5.6-sol' },
        'frontend-builder': { model: 'openai/gpt-5.6-sol' },
        explore: { model: 'openai/gpt-5.6-sol' },
        general: { model: 'openai/gpt-5.6-sol' },
      },
    });
  } finally {
    if (previous === undefined) delete process.env.OC_ORCH;
    else process.env.OC_ORCH = previous;
  }
});

test('inactive when OC_ORCH is empty', async () => {
  const previous = process.env.OC_ORCH;
  try {
    process.env.OC_ORCH = '';
    const original = { model: 'openai/gpt-6-astra-fast', agent: { build: { model: 'x/y' } } };
    const clone = structuredClone(original);
    await (await builder()).config?.(clone);
    assert.deepEqual(clone, original);
  } finally {
    if (previous === undefined) delete process.env.OC_ORCH;
    else process.env.OC_ORCH = previous;
  }
});
