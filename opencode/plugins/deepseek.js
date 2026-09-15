const MODEL = 'fireworks-ai/accounts/fireworks/models/deepseek-v4p1-flash';

export default async () => {
  if (process.env.OC_DEEPSEEK !== '1') return {};

  const replaceModel = (entry, key) => {
    if (typeof entry[key] === 'string' && /^[^/]+\/gpt-[^/]*-astra(?:-[^/]+)?$/.test(entry[key])) {
      entry[key] = MODEL;
      entry.variant = 'max';
    }
  };

  return {
    config: async (config) => {
      replaceModel(config, 'model');
      replaceModel(config, 'small_model');
      for (const agent of Object.values(config.agent ?? {})) {
        replaceModel(agent, 'model');
      }

      const fireworks = config.provider ??= {};
      fireworks['fireworks-ai'] ??= {};
      const models = fireworks['fireworks-ai'].models ??= {};
      models['accounts/fireworks/models/deepseek-v4p1-flash'] ??= {};
      models['accounts/fireworks/models/deepseek-v4p1-flash'].variants ??= {};
      models['accounts/fireworks/models/deepseek-v4p1-flash'].variants.max ??= {};
      models['accounts/fireworks/models/deepseek-v4p1-flash'].variants.max = { reasoningEffort: 'max' };
    },
  };
};
