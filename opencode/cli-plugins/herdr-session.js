import { request } from '../plugins/herdr-state.js';

// Re-report a new selection a few times so it wins races with server-side reports.
const SELECTION_RETRY_DELAYS_MS = [100, 400, 1_000];

export default {
  id: 'dotfiles.herdr-session',
  async setup(ctx) {
    if (process.env.HERDR_ENV !== '1' || !process.env.HERDR_SOCKET_PATH || !process.env.HERDR_PANE_ID) return;

    let selectedSessionID;
    let retryIndex = 0;
    let nextReportAt = 0;
    let pending = false;
    const sync = async () => {
      const route = ctx.ui.router.current();
      const sessionID = route?.type === 'session' ? route.sessionID : undefined;
      const session = sessionID ? ctx.data.session.get(sessionID) : undefined;
      if (!session || session.parentID) {
        selectedSessionID = undefined;
        return;
      }
      if (sessionID !== selectedSessionID) {
        selectedSessionID = sessionID;
        retryIndex = 0;
        nextReportAt = 0;
      }
      if (pending || Date.now() < nextReportAt) return;
      pending = true;
      try {
        // CLI and server processes cannot share a monotonic report sequence.
        await request('pane.report_agent_session', { agent_session_id: sessionID, session_start_source: 'select', seq: undefined });
      } finally {
        pending = false;
      }
      if (selectedSessionID !== sessionID) return;
      const delay = SELECTION_RETRY_DELAYS_MS[retryIndex++];
      nextReportAt = delay === undefined ? Number.POSITIVE_INFINITY : Date.now() + delay;
    };
    await sync();
    const timer = setInterval(() => void sync().catch(console.error), 100);
    return () => clearInterval(timer);
  },
};
