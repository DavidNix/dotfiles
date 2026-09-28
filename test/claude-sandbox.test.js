'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const repo = path.resolve(__dirname, '..');
let fixture;

before(() => {
    const root = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'cc sandbox test.')));
    const home = path.join(root, 'home');
    const work = path.join(root, 'work');
    const outside = path.join(root, 'outside');
    const bin = path.join(root, 'bin');
    for (const dir of [home, work, outside, bin, path.join(home, '.claude'), path.join(home, '.config'), path.join(home, '.local', 'share')]) {
        fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(path.join(home, '.claude.json'), '{}');
    fs.writeFileSync(path.join(outside, 'settings.json'), '{}');
    fs.symlinkSync(path.join(outside, 'settings.json'), path.join(home, '.claude', 'settings.json'));
    fs.writeFileSync(path.join(bin, 'claude'), [
        '#!/bin/bash',
        'set -euo pipefail',
        'if [[ "${1:-}" == mktemp-probe ]]; then',
        '  printf "tmpdir=%s\\n" "$TMPDIR"',
        '  printf "bare=%s\\n" "$(mktemp)"',
        '  d=$(mktemp -d); [[ -d "$d" ]]; printf "dir=%s\\n" "$d"',
        '  printf "prefix=%s\\n" "$(mktemp -t probe)"',
        '  d=$(mktemp -dqt probe); [[ -d "$d" ]]; printf "combined=%s\\n" "$d"',
        '  d=$(mktemp --directory); [[ -d "$d" ]]; printf "long=%s\\n" "$d"',
        '  printf "tmpdir-relative=%s\\n" "$(mktemp --tmpdir rel.XXXXXX)"',
        '  printf "explicit=%s\\n" "$(mktemp explicit.XXXXXX)"',
        '  exit 0',
        'fi',
        'printf "argc=%s\\n" "$#"',
        'i=0; for arg in "$@"; do printf "arg-%s=<%s>\\n" "$i" "$arg"; i=$((i+1)); done',
        'printf "tmpdir=%s\\n" "${TMPDIR:-unset}"',
        'printf "cctmp=%s\\n" "${CLAUDE_CODE_TMPDIR:-unset}"',
        'printf "configdir=%s\\n" "${CLAUDE_CONFIG_DIR:-unset}"',
        'exit "${CC_TEST_EXIT:-0}"',
        '',
    ].join('\n'), { mode: 0o755 });
    const runner = path.join(root, 'runner.sh');
    fs.writeFileSync(runner, [
        '#!/bin/bash',
        'function /usr/bin/sandbox-exec {',
        '  printf "%s\\n" "$@" > "$CC_TEST_PROFILE_ARGS"',
        '  while [[ "$1" != -- ]]; do shift; done',
        '  shift',
        '  "$@"',
        '}',
        'source "$1" "${@:2}"',
        '',
    ].join('\n'));
    fixture = { root, home, work, outside, bin, runner };
});

after(() => fs.rmSync(fixture.root, { recursive: true, force: true }));

function run(args, extraEnv = {}) {
    const profileArgs = path.join(fixture.root, 'profile-args');
    fs.rmSync(profileArgs, { force: true });
    const result = spawnSync('/bin/bash', [fixture.runner, path.join(repo, 'bin', 'claude-sandbox'), ...args], {
        cwd: fixture.work,
        encoding: 'utf8',
        env: {
            PATH: `${fixture.bin}:/usr/bin:/bin`,
            HOME: fixture.home,
            TMPDIR: fixture.root,
            XDG_CONFIG_HOME: path.join(fixture.home, '.config'),
            XDG_CACHE_HOME: path.join(fixture.home, '.cache'),
            XDG_DATA_HOME: path.join(fixture.home, '.local/share'),
            XDG_STATE_HOME: path.join(fixture.home, '.local/state'),
            CC_TEST_PROFILE_ARGS: profileArgs,
            ...extraEnv,
        },
        timeout: 20000,
    });
    return { ...result, profile: fs.existsSync(profileArgs) ? fs.readFileSync(profileArgs, 'utf8') : '' };
}

test('Claude runs in the shared write-isolation profile with only Claude state writable', () => {
    const r = run(['-p', 'two words']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /argc=2\narg-0=<-p>\narg-1=<two words>/);
    assert.match(r.stdout, /tmpdir=.*cc-sandbox-/);
    assert.match(r.profile, /\(deny default\)/);
    assert.match(r.profile, /-DWRITABLE_ROOT_\d+=.*\/work\n/);
    assert.match(r.profile, /-DWRITABLE_ROOT_\d+=.*\/home\/\.claude\n/);
    assert.match(r.profile, /-DWRITABLE_FILE_\d+=.*\/home\/\.claude\.json\n/);
    assert.match(r.profile, /-DWRITABLE_FILE_\d+=.*\/outside\/settings\.json\n/);
    assert.doesNotMatch(r.profile, /-DWRITABLE_ROOT_\d+=.*\/home\n/);
    assert.doesNotMatch(r.profile, /-DWRITABLE_ROOT_\d+=.*\/outside\n/);
    const tmp = r.stdout.match(/tmpdir=(.*)/)?.[1];
    assert.ok(tmp);
    assert.ok(r.stdout.includes(`cctmp=${tmp}\n`), 'Claude temp dir is inside the writable sandbox temp dir');
    assert.equal(fs.existsSync(tmp), false);
});

test('Claude passes flags after -- and propagates exit status', () => {
    const r = run(['--', '--help'], { CC_TEST_EXIT: '17' });
    assert.equal(r.status, 17, r.stderr);
    assert.match(r.stdout, /arg-0=<--help>/);
});

test('without sandbox launches directly without modifying environment', () => {
    const r = run(['--without-sandbox', '--version']);
    assert.equal(r.status, 0, r.stderr);
    assert.equal(r.profile, '');
    assert.match(r.stdout, /arg-0=<--version>/);
    assert.match(r.stdout, new RegExp(`tmpdir=${fixture.root}\\n`));
    assert.match(r.stdout, /cctmp=unset\n/);
});

test('mktemp without a template uses the sandbox temp dir instead of the blocked per-user temp dir', () => {
    const r = run(['mktemp-probe']);
    assert.equal(r.status, 0, r.stderr);
    const out = Object.fromEntries(r.stdout.trim().split('\n').map((line) => {
        const i = line.indexOf('=');
        return [line.slice(0, i), line.slice(i + 1)];
    }));
    for (const key of ['bare', 'dir', 'prefix', 'combined', 'long', 'tmpdir-relative']) {
        assert.equal(path.dirname(out[key]), out.tmpdir, key);
    }
    assert.match(path.basename(out.prefix), /^probe\.\w{10}$/);
    assert.match(path.basename(out['tmpdir-relative']), /^rel\.\w{6}$/);
    assert.match(out.explicit, /^explicit\.\w{6}$/, 'relative templates stay relative to the working directory');
});

test('custom Claude config directory is writable without making its parent writable', () => {
    const config = path.join(fixture.outside, 'custom-claude');
    fs.mkdirSync(config, { recursive: true });
    const r = run(['-p', 'custom'], { CLAUDE_CONFIG_DIR: config });
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.profile, /-DWRITABLE_ROOT_\d+=.*\/outside\/custom-claude\n/);
    assert.doesNotMatch(r.profile, /-DWRITABLE_ROOT_\d+=.*\/outside\n/);
});

test('a not-yet-created symlinked settings file can be written at its target', () => {
    const link = path.join(fixture.home, '.claude', 'settings.local.json');
    fs.symlinkSync(path.join(fixture.outside, 'local-settings.json'), link);
    const r = run(['-p', 'settings']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.profile, /-DWRITABLE_FILE_\d+=.*\/outside\/local-settings\.json\n/);
});

test('sidecar policy escapes regex metacharacters but preserves spaces in paths', () => {
    const r = run(['-p', 'probe']);
    assert.equal(r.status, 0, r.stderr);
    assert.ok(r.profile.includes('cc sandbox test\\.'), 'space is a literal regex character');
    assert.match(r.profile, /\\\.claude\\\.json\\\.\(tmp\|lock\)/);
});

test('symlinked settings may use adjacent atomic-save files at their target', () => {
    const r = run(['-p', 'probe']);
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.profile, /\/outside\/settings\\\.json\\\.\(tmp\|lock\)/);
    assert.doesNotMatch(r.profile, /-DWRITABLE_ROOT_\d+=.*\/outside\n/);
});
