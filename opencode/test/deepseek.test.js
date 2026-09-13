import assert from 'node:assert/strict';
import test from 'node:test';
import deepseek from '../plugins/deepseek.js';

test('flag replaces only Astra model selections in the merged config', async () => {
  const previous = process.env.OC_DEEPSEEK;
  try {
    const original = {
      model: 'openai/gpt-6-astra-fast',
      small_model: 'openai/gpt-6-astra',
      agent: {
        review: { model: 'openai/gpt-6-astra-fast', permission: { edit: 'deny' } },
        custom: { model: 'other/gpt-7-astra' },
        summary: { model: 'openai/gpt-5.6-luna' },
        inherited: { mode: 'subagent' },
      },
      permission: { bash: 'ask' },
    };
    delete process.env.OC_DEEPSEEK;
    const inactive = structuredClone(original);
    await (await deepseek()).config?.(inactive);
    assert.deepEqual(inactive, original);

    process.env.OC_DEEPSEEK = '1';
    const active = structuredClone(original);
    await (await deepseek()).config?.(active);
    const expected = structuredClone(original);
    expected.model = expected.small_model = expected.agent.review.model =
      expected.agent.custom.model = 'opencode-go/deepseek-v4.1-flash';
    assert.deepEqual(active, expected);
  } finally {
    if (previous === undefined) delete process.env.OC_DEEPSEEK;
    else process.env.OC_DEEPSEEK = previous;
  }
});
