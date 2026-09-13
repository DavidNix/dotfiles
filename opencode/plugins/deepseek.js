export default async () => {
  if (process.env.OC_DEEPSEEK !== '1') return {};

  const replaceModel = (entry, key) => {
    if (typeof entry[key] === 'string' && /^[^/]+\/gpt-[^/]*-astra(?:-[^/]+)?$/.test(entry[key])) {
      entry[key] = 'opencode-go/deepseek-v4.1-flash';
    }
  };

  return {
    config: async (config) => {
      replaceModel(config, 'model');
      replaceModel(config, 'small_model');
      for (const agent of Object.values(config.agent ?? {})) {
        replaceModel(agent, 'model');
      }
    },
  };
};
