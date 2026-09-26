export default async () => {
  const model = process.env.OC_ORCH;
  const primaryModel = process.env.OC_PRIMARY;
  if (!model && !primaryModel) return {};

  return {
    config: async (config) => {
      const agents = config.agent ??= {};
      if (primaryModel) {
        for (const name of ['plan', 'build', 'prototype']) {
          const agent = agents[name] ??= {};
          agent.model = primaryModel;
        }
      }
      if (model) {
        for (const name of ['builder', 'frontend-builder', 'explore', 'general']) {
          const agent = agents[name] ??= {};
          agent.model = model;
        }
      }
    },
  };
};
