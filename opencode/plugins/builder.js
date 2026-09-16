export default async () => {
  const model = process.env.OC_ORCH;
  if (!model) return {};

  return {
    config: async (config) => {
      const agents = config.agent ??= {};
      for (const name of ['builder', 'frontend-builder', 'explore', 'general']) {
        const agent = agents[name] ??= {};
        agent.model = model;
      }
    },
  };
};