'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const REPO = path.resolve(__dirname, '..');
const OC = path.join(REPO, 'bin', 'oc');
const BASH = '/bin/bash';
const TIMEOUT_MS = 20000;

let f;

before(() => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'oc-pw-test.'));
    const fakeBin = path.join(root, 'bin');
    const homeDir = path.join(root, 'home');
    const workDir = path.join(root, 'workspace');
    const runner = path.join(root, 'runner.sh');
    const realCli = path.join(fakeBin, 'playwright-cli');

    for (const d of [fakeBin, homeDir, path.join(workDir, '.playwright'), path.join(homeDir, '.config'), path.join(homeDir, '.cache')]) {
        fs.mkdirSync(d, { recursive: true });
    }

    fs.writeFileSync(runner, [
        '#!/bin/bash',
        // Exercise the wrapper, not macOS policy: nested Seatbelt profiles are rejected.
        'function /usr/bin/sandbox-exec { while [[ "$1" != -- ]]; do shift; done; shift; "$@"; }',
        'source "$1" "${@:2}"',
        '',
    ].join('\n'));

    fs.writeFileSync(path.join(fakeBin, 'curl'), ['#!/bin/bash', 'exit 0', ''].join('\n'));

    fs.writeFileSync(realCli, [
        '#!/bin/bash',
        'set -euo pipefail',
        "printf 'real-cli=hit\\n'",
        "printf 'real-argc=%s\\n' \"$#\"",
        'i=0',
        'for a in "$@"; do printf \'real-arg-%s=<%s>\\n\' "$i" "$a"; i=$((i+1)); done',
        "printf 'real-cdp=%s\\n' \"${PLAYWRIGHT_MCP_CDP_ENDPOINT:-unset}\"",
        "printf 'real-browser=%s\\n' \"${PLAYWRIGHT_MCP_BROWSER:-unset}\"",
        "printf 'real-socketdir=%s\\n' \"${PWTEST_SOCKETS_DIR:-unset}\"",
        'config_file=.playwright/cli.config.json',
        'for a in "$@"; do [[ "$a" != --config=* ]] || config_file="${a#--config=}"; done',
        "printf 'real-config=<%s>\\n' \"$(<\"$config_file\")\"",
        "printf 'real-version=1.2.3-test\\n'",
        '',
    ].join('\n'));

    fs.writeFileSync(path.join(fakeBin, 'opencode'), [
        '#!/bin/bash',
        'set -euo pipefail',
        'if [[ "${1:-}" == "playwright-call" ]]; then',
        '  shift',
        '  exec playwright-cli "$@"',
        'fi',
        'if [[ "${1:-}" == "nested-probe" ]]; then',
        '  if [[ "${OC_PLAYWRIGHT_CLI_BIN:-}" != "$OC_TEST_REAL_CLI" ]]; then',
        "    printf 'nested-bad-bin=<%s>\\n' \"${OC_PLAYWRIGHT_CLI_BIN:-}\"",
        '    exit 1',
        '  fi',
        '  playwright-cli --version',
        "  printf 'nested-ok\\n'",
        '  exit 0',
        'fi',
        'if [[ "${1:-}" == "double-nested" ]]; then',
        '  bash "$OC_TEST_RUNNER" "$OC_TEST_OC" nested-probe',
        '  exit $?',
        'fi',
        "printf 'oc-cdp=%s\\n' \"${PLAYWRIGHT_MCP_CDP_ENDPOINT:-unset}\"",
        "printf 'oc-browser=%s\\n' \"${PLAYWRIGHT_MCP_BROWSER:-unset}\"",
        "printf 'oc-socketdir=%s\\n' \"${PWTEST_SOCKETS_DIR:-unset}\"",
        "printf 'oc-clibin=%s\\n' \"${OC_PLAYWRIGHT_CLI_BIN:-unset}\"",
        "printf 'oc-cliconfig=%s\\n' \"${OC_PLAYWRIGHT_CLI_CONFIG:-unset}\"",
        "printf 'oc-ansible-local-temp=%s\\n' \"${ANSIBLE_LOCAL_TEMP:-unset}\"",
        'if [[ -n "${ANSIBLE_LOCAL_TEMP:-}" && -d "$ANSIBLE_LOCAL_TEMP" && -w "$ANSIBLE_LOCAL_TEMP" ]]; then',
        "  printf 'oc-ansible-local-temp-writable=yes\\n'",
        'else',
        "  printf 'oc-ansible-local-temp-writable=no\\n'",
        'fi',
        "printf 'oc-argc=%s\\n' \"$#\"",
        'i=0',
        'for a in "$@"; do printf \'oc-arg-%s=<%s>\\n\' "$i" "$a"; i=$((i+1)); done',
        'exit 0',
        '',
    ].join('\n'));

    fs.writeFileSync(path.join(workDir, '.playwright', 'cli.config.json'), '{"testIdAttribute":"project-sentinel"}');
    fs.writeFileSync(path.join(workDir, 'explicit config.json'), '{"testIdAttribute":"explicit-sentinel"}');

    for (const p of [path.join(fakeBin, 'curl'), realCli, path.join(fakeBin, 'opencode')]) {
        fs.chmodSync(p, 0o755);
    }

    f = {
        root, fakeBin, homeDir, workDir, runner, realCli,
        baseEnv: {
            PATH: `${fakeBin}:/usr/bin:/bin`,
            HOME: homeDir,
            XDG_CONFIG_HOME: path.join(homeDir, '.config'),
            XDG_CACHE_HOME: path.join(homeDir, '.cache'),
            XDG_DATA_HOME: path.join(homeDir, '.local/share'),
            XDG_STATE_HOME: path.join(homeDir, '.local/state'),
            TMPDIR: root,
            OC_TEST_REAL_CLI: realCli,
            OC_TEST_RUNNER: runner,
            OC_TEST_OC: OC,
        },
    };
});

after(() => {
    fs.rmSync(f.root, { recursive: true, force: true });
});

function runOc(args, extraEnv = {}) {
    const res = spawnSync(BASH, [f.runner, OC, ...args], {
        cwd: f.workDir,
        env: { ...f.baseEnv, ...extraEnv },
        encoding: 'utf8',
        timeout: TIMEOUT_MS,
        maxBuffer: 4 * 1024 * 1024,
    });
    return {
        status: res.status,
        stdout: res.stdout,
        stderr: res.stderr,
        timedOut: res.signal === 'SIGTERM',
    };
}

test('open args reach real CLI unchanged (no injected config)', () => {
    const r = runOc(['playwright-call', 'open', 'about:blank', '--bare']);
    assert.equal(r.timedOut, false, r.stderr);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /real-argc=3/);
    assert.match(r.stdout, /real-arg-0=<open>/);
    assert.match(r.stdout, /real-arg-1=<about:blank>/);
    assert.match(r.stdout, /real-arg-2=<--bare>/);
    assert.doesNotMatch(r.stdout, /real-arg-0=<--config/);
});

test('default .playwright/cli.config.json is discoverable by the stub', () => {
    const r = runOc(['playwright-call', 'open', 'about:blank']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /real-config=<{"testIdAttribute":"project-sentinel"}>/);
    assert.doesNotMatch(r.stdout, /real-arg-0=<--config/);
});

test('explicit --config is passed through unchanged (space in path)', () => {
    const explicit = path.join(f.workDir, 'explicit config.json');
    const r = runOc(['playwright-call', 'open', `--config=${explicit}`, 'foo']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /real-argc=3/);
    assert.match(r.stdout, /real-arg-1=<--config=[^>]*explicit config\.json>/);
    assert.match(r.stdout, /real-config=<{"testIdAttribute":"explicit-sentinel"}>/);
});

test('env CDP endpoint/browser override conflicting inherited values', () => {
    const r = runOc(['playwright-call', 'open', 'about:blank'], {
        PLAYWRIGHT_MCP_CDP_ENDPOINT: 'http://127.0.0.1:9999',
        PLAYWRIGHT_MCP_BROWSER: 'firefox',
        OC_PLAYWRIGHT_CLI_BIN: '/bogus/playwright-cli',
    });
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /real-cli=hit/);
    assert.match(r.stdout, /real-cdp=http:\/\/127\.0\.0\.1:9222/);
    assert.match(r.stdout, /real-browser=chromium/);
});

test('nested wrappers reach the real CLI', () => {
    const r = runOc(['double-nested']);
    assert.equal(r.timedOut, false, r.stderr);
    assert.equal(r.status, 0, r.stderr);
    assert.doesNotMatch(r.stdout, /nested-bad-bin/);
    assert.match(r.stdout, /nested-ok/);
    assert.match(r.stdout, /real-cli=hit/);
    assert.match(r.stdout, /real-version=1\.2\.3-test/);
});

test('ansible local temp is writable inside the sandbox temp root', () => {
    const r = runOc(['probe']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /oc-ansible-local-temp=.*\/oc-sandbox-[^/]+\/ansible/);
    assert.match(r.stdout, /oc-ansible-local-temp-writable=yes/);
});

test('--without-sandbox adds no PWTEST_SOCKETS_DIR or playwright env', () => {
    const r = runOc(['--without-sandbox', 'probe', 'arg']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /oc-socketdir=unset/);
    assert.match(r.stdout, /oc-clibin=unset/);
    assert.match(r.stdout, /oc-cliconfig=unset/);
    assert.match(r.stdout, /oc-cdp=unset/);
    assert.match(r.stdout, /oc-browser=unset/);
});
