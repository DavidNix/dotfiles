// Dotfiles-owned V2 adapter for Herdr's pane reporting protocol.

import net from "node:net";

const SOURCE = "herdr:opencode";
const AGENT = "opencode";
let reportSeq = Date.now() * 1000;
let requestChain = Promise.resolve();

// Track child sessions so their events cannot replace the pane's root session.
// Their user prompts still project state without attaching the child session id.
const CHILD_EVENT_STATES = new Map([
  ["permission.asked", "blocked"],
  ["form.created", "blocked"],
  ["permission.replied", "working"],
  ["form.replied", "working"],
  ["form.cancelled", "working"],
]);

function nextReportSeq() {
  reportSeq += 1;
  return reportSeq;
}

const SESSION_STATE_BY_STATUS = new Map([
  ["idle", "idle"],
  ["busy", "working"],
  ["retry", "working"],
]);

function stateFromSessionStatus(status) {
  const kind = typeof status === "string" ? status : status?.type;
  return typeof kind === "string"
    ? SESSION_STATE_BY_STATUS.get(kind.toLowerCase())
    : undefined;
}

export function request(method, params) {
  const pending = requestChain.then(() => requestOnce(method, params));
  requestChain = pending.catch(() => {});
  return pending;
}

function requestOnce(method, params) {
  const paneId = process.env.HERDR_PANE_ID;
  const socketPath = process.env.HERDR_SOCKET_PATH;

  if (!paneId || !socketPath) {
    return Promise.resolve();
  }

  const socketEndpoint =
    process.platform === "win32" ? `\\\\.\\pipe\\${socketPath}` : socketPath;

  const requestId = `${SOURCE}:${Date.now()}:${Math.floor(Math.random() * 1_000_000)
    .toString()
    .padStart(6, "0")}`;
  const request = {
    id: requestId,
    method,
    params: {
      pane_id: paneId,
      source: SOURCE,
      agent: AGENT,
      seq: nextReportSeq(),
      ...params,
    },
  };

  return new Promise((resolve) => {
    const client = net.createConnection(socketEndpoint, () => {
      client.write(`${JSON.stringify(request)}\n`);
    });

    const finish = () => {
      client.destroy();
      resolve();
    };

    client.setTimeout(500, finish);
    client.on("data", finish);
    client.on("error", finish);
    client.on("end", finish);
    client.on("close", resolve);
  });
}

function reportSession(sessionID) {
  if (!sessionID) {
    return Promise.resolve();
  }
  return request("pane.report_agent_session", { agent_session_id: sessionID });
}

function reportState(state, sessionID) {
  const params = { state };
  if (sessionID) {
    params.agent_session_id = sessionID;
  }
  return request("pane.report_agent", params);
}

export const HerdrAgentStatePlugin = {
  id: "dotfiles.herdr-state",
  async setup(ctx) {
    if (
      process.env.HERDR_ENV !== "1" ||
      !process.env.HERDR_SOCKET_PATH ||
      !process.env.HERDR_PANE_ID
    ) {
      return;
    }

    const childSessions = new Set();
    await ctx.session.hook("prompt", async ({ sessionID }) => {
      const session = await ctx.session.get({ sessionID });
      if (session.parentID) {
        childSessions.add(sessionID);
        return;
      }
      await reportState("working", sessionID);
    });

    const controller = new AbortController();
    const observe = async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.location?.directory && event.location.directory !== ctx.location.directory) continue;
        const type = event.type;
        const data = event.data ?? {};
        const sessionID = data.sessionID ?? data.form?.sessionID;

        if (type === "session.created" && data.parentID) {
          childSessions.add(sessionID);
        }
        if (sessionID && childSessions.has(sessionID)) {
          const state = CHILD_EVENT_STATES.get(type);
          if (state) await reportState(state);
          continue;
        }

        switch (type) {
          case "session.renamed":
            await reportSession(sessionID);
            break;
          case "session.status": {
            const state = stateFromSessionStatus(data.status);
            if (state) await reportState(state, sessionID);
            else await reportSession(sessionID);
            break;
          }
          case "session.execution.started":
          case "permission.replied":
          case "form.replied":
          case "form.cancelled":
            await reportState("working", sessionID);
            break;
          case "permission.asked":
          case "form.created":
          case "session.execution.failed":
            await reportState("blocked", sessionID);
            break;
          case "session.execution.succeeded":
          case "session.execution.interrupted":
            await reportState("idle", sessionID);
            break;
        }
      }
    };
    void observe().catch(error => {
      if (!controller.signal.aborted) console.error("Herdr event stream:", error);
    });
    return () => controller.abort();
  },
};

export default HerdrAgentStatePlugin;
