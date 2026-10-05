import assert from 'node:assert/strict';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { once } from 'node:events';
import { setTimeout as delay } from 'node:timers/promises';
import test from 'node:test';
import { HerdrAgentStatePlugin } from '../plugins/herdr-state.js';
import selection from '../cli-plugins/herdr-session.js';

async function receiver(t) {
  // macOS Unix sockets have a short path limit; the system temp path is too long.
  const directory = fs.mkdtempSync(path.join(process.cwd(), '.herdr-test.'));
  const socketPath = path.join(directory, 'h.sock');
  const reports = [];
  const server = net.createServer(socket => {
    let text = '';
    socket.on('data', chunk => {
      text += chunk;
      if (!text.includes('\n')) return;
      reports.push(JSON.parse(text).params);
      socket.end('{}\n');
    });
  });
  server.listen(socketPath);
  await once(server, 'listening');
  const previous = {};
  for (const [key, value] of Object.entries({ HERDR_ENV: '1', HERDR_SOCKET_PATH: socketPath, HERDR_PANE_ID: 'pane-test' })) {
    previous[key] = process.env[key];
    process.env[key] = value;
  }
  t.after(async () => {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
    await new Promise(resolve => server.close(resolve));
    fs.rmSync(directory, { recursive: true, force: true });
  });
  return reports;
}

test('V2 events report root and child state without replacing the pane root, and cleanup aborts the stream', async t => {
  const reports = await receiver(t);
  let signal;
  const events = [
    { type: 'session.created', data: { sessionID: 'root' } },
    { type: 'session.status', data: { sessionID: 'root', status: { type: 'busy' } } },
    { type: 'session.created', data: { sessionID: 'child', parentID: 'root' } },
    { type: 'permission.asked', data: { sessionID: 'child' } },
    { type: 'form.created', data: { form: { sessionID: 'root' } } },
    { type: 'form.replied', data: { sessionID: 'root' } },
    { type: 'session.execution.succeeded', data: { sessionID: 'root' } },
  ];
  const cleanup = await HerdrAgentStatePlugin.setup?.({
    location: { directory: process.cwd() },
    session: { hook: async () => {} },
    event: { subscribe: async function* (options) {
      signal = options.signal;
      yield* events;
    } },
  });
  assert.equal(typeof cleanup, 'function');
  t.after(cleanup);
  for (let i = 0; i < 100 && reports.length < 5; i++) await delay(10);
  assert.deepEqual(reports.map(report => [report.state, report.agent_session_id]), [
    ['working', 'root'], ['blocked', undefined], ['blocked', 'root'], ['working', 'root'], ['idle', 'root'],
  ]);
  cleanup();
  assert.equal(signal.aborted, true);
});

test('V2 CLI selection reports the selected root and stops polling on disposal', async t => {
  const reports = await receiver(t);
  let route = { type: 'session', sessionID: 'root' };
  const cleanup = await selection.setup({
    ui: { router: { current: () => route } },
    data: { session: { get: id => ({ id, ...(id === 'child' ? { parentID: 'root' } : {}) }) } },
  });
  assert.equal(typeof cleanup, 'function');
  t.after(cleanup);
  assert.equal(reports[0]?.agent_session_id, 'root');
  assert.equal(reports[0]?.session_start_source, 'select');
  assert.equal(reports[0]?.seq, undefined);
  route = { type: 'session', sessionID: 'child' };
  await delay(120);
  assert.equal(reports.length, 1);
  cleanup();
  route = { type: 'session', sessionID: 'other-root' };
  await delay(120);
  assert.equal(reports.length, 1);
});

test('V2 CLI selection re-reports a new root to win races with server reports', async t => {
  const reports = await receiver(t);
  const cleanup = await selection.setup({
    ui: { router: { current: () => ({ type: 'session', sessionID: 'root' }) } },
    data: { session: { get: id => ({ id }) } },
  });
  t.after(cleanup);
  for (let i = 0; i < 100 && reports.length < 3; i++) await delay(20);
  cleanup();
  assert.ok(reports.length >= 3, `expected retries, got ${reports.length} reports`);
  assert.ok(reports.every(report => report.agent_session_id === 'root'));
});
