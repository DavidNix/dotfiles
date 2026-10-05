const CONFIG_TIMEOUT_MS = 10_000;

const parseModel = (selection) => {
  const [reference, variant] = selection.split('#');
  const slash = reference.indexOf('/');
  if (slash < 1 || slash === reference.length - 1) return;
  return { providerID: reference.slice(0, slash), id: reference.slice(slash + 1), variant };
};

export default {
  id: 'dotfiles.builder',
  async setup(ctx) {
    const overrides = [
      [['plan', 'build', 'prototype'], process.env.OC_PRIMARY],
      [['builder', 'frontend-builder', 'explore', 'general'], process.env.OC_ORCH],
      [['title', 'summary'], process.env.OC_SMALL],
    ].flatMap(([names, selection]) => {
      if (!selection) return [];
      const model = parseModel(selection);
      if (model) return [{ names, model }];
      console.error(`Builder overrides: invalid model ${selection}; expected provider/model[#variant]`);
      return [];
    });
    if (!overrides.length) return;

    const transform = (editor) => {
      for (const { names, model: { variant, ...model } } of overrides) {
        for (const name of names) {
          editor.update(name, (agent) => {
            const selected = variant || agent.model?.variant;
            agent.model = { ...model, ...(selected ? { variant: selected } : {}) };
          });
        }
      }
    };
    let registration = await ctx.agent.transform(transform);
    // Missing until the built-in loads. A failed built-in applies no authored agents.
    const configStatus = async () => (await ctx.plugin.list()).data
      .find(plugin => plugin.id === 'opencode.config.agent')?.state.status;
    if (await configStatus()) return;

    // V2 applies authored agent config after loading external plugins.
    // Re-register last once that built-in is active so flags take precedence.
    const controller = new AbortController();
    let ready;
    const configuredModel = new Promise(resolve => { ready = resolve; });
    const timeout = setTimeout(() => {
      console.error('Builder overrides: agent config did not load; releasing prompts');
      ready();
    }, CONFIG_TIMEOUT_MS);
    void configuredModel.then(() => clearTimeout(timeout));
    await ctx.session.hook('prompt', () => configuredModel);
    const observe = async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (!['server.connected', 'plugin.updated'].includes(event.type)) continue;
        const status = await configStatus();
        if (!status) continue;
        if (status === 'active') {
          await registration.dispose();
          registration = await ctx.agent.transform(transform);
        }
        ready();
        break;
      }
    };
    void observe().catch(error => {
      ready();
      if (!controller.signal.aborted) console.error('Builder overrides:', error);
    });
    return () => {
      controller.abort();
      ready();
    };
  },
};
