export default async () => {
  const model = process.env.OC_ORCH;
  if (!model) return {};

  return {
    config: async (config) => {
      const agents = config.agent ??= {};
      for (const name of ['build', 'explore', 'general']) {
        const agent = agents[name];
        if (agent) agent.model = model;
      }
    },
  };
};