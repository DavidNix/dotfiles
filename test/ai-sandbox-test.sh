#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${REPO_DIR}/bin/_ai-sandbox-common.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected actual label

    expected="$1"
    actual="$2"
    label="$3"

    [[ "$actual" == "$expected" ]] || fail "${label}: expected '${expected}', got '${actual}'"
}

assert_contains() {
    local needle haystack label

    needle="$1"
    haystack="$2"
    label="$3"

    [[ "$haystack" == *"$needle"* ]] || fail "${label}: expected '${haystack}' to contain '${needle}'"
}

assert_not_contains() {
    local needle haystack label

    needle="$1"
    haystack="$2"
    label="$3"

    [[ "$haystack" != *"$needle"* ]] || fail "${label}: did not expect '${haystack}' to contain '${needle}'"
}

test_gomodcache_must_stay_under_home() {
    local output

    GOMODCACHE="${HOME}/go/pkg/mod" output="$(_ai_sandbox_default_gomodcache)"
    assert_eq "$(_ai_sandbox_realpath "${HOME}/go/pkg/mod")" "$output" "user GOMODCACHE"

    if (GOMODCACHE="/tmp/not-under-home" _ai_sandbox_default_gomodcache) >/dev/null 2>&1; then
        fail "GOMODCACHE outside HOME should be rejected"
    fi
}

test_env_filter_rejects_secrets() {
    _ai_sandbox_env_name_allowed "DIRENV_DIR" || fail "DIRENV_DIR should be allowed"
    _ai_sandbox_env_name_allowed "AWS_REGION" || fail "AWS_REGION should be allowed"

    if _ai_sandbox_env_name_allowed "DIRENV_DIFF"; then
        fail "DIRENV_DIFF should be rejected because it can contain prior env values"
    fi
    if _ai_sandbox_env_name_allowed "AWS_SECRET_ACCESS_KEY"; then
        fail "AWS_SECRET_ACCESS_KEY should be rejected"
    fi
    if _ai_sandbox_env_name_allowed "GITHUB_TOKEN"; then
        fail "GITHUB_TOKEN should be rejected"
    fi
}

test_clean_env_keeps_direnv_and_drops_secrets() {
    local output

    output="$(_ai_sandbox_build_clean_env \
        "${HOME}/tmp/ai-sandbox-test" \
        "${HOME}/go/pkg/mod" \
        "${HOME}/tmp/ai-sandbox-test/go-build" \
        "DIRENV_DIR=-/repo" \
        "AWS_SECRET_ACCESS_KEY=secret" \
        "OPENCODE_CONFIG=${HOME}/.config/opencode/opencode-yolo.jsonc")"

    assert_contains "DIRENV_DIR=-/repo" "$output" "clean env direnv"
    assert_contains $'OPENCODE_CONFIG=' "$output" "clean env explicit wrapper var"
    assert_not_contains "AWS_SECRET_ACCESS_KEY" "$output" "clean env secret filtering"
}

test_project_temp_dir_is_per_project_and_under_home() {
    local first second

    first="$(_ai_sandbox_project_temp_dir "/tmp/project one")"
    second="$(_ai_sandbox_project_temp_dir "/tmp/project two")"

    assert_contains "${HOME}/.cache/ai-sandbox/tmp/" "$first" "project temp root"
    [[ "$first" != "$second" ]] || fail "different projects should get different temp dirs"
}

test_managed_dir_rejects_symlink_escape() {
    local root

    root="$(mktemp -d)"
    ln -s /tmp "${root}/escape"
    if (_ai_sandbox_prepare_managed_dir "${root}/escape/cache" "$root") >/dev/null 2>&1; then
        fail "managed dir should reject symlink escape"
    fi
    rm -rf "$root"
}

test_plugin_write_deny_rule() {
    local rule

    rule="$(_ai_sandbox_build_deny_rules "${HOME}/.config/opencode/plugins")"
    assert_contains "file-write*" "$rule" "plugin deny write"
    assert_contains "$(_ai_sandbox_realpath "${HOME}/.config/opencode/plugins")" "$rule" "plugin deny path"
}

test_profile_uses_project_temp_only() {
    local profile

    profile="$(_ai_sandbox_render_profile "" "" "" "")"
    assert_contains '(subpath (param "TMP_DIR"))' "$profile" "profile temp dir"
    assert_not_contains '(subpath "/tmp")' "$profile" "profile broad tmp"
    assert_not_contains '(subpath "/private/tmp")' "$profile" "profile broad private tmp"
    assert_not_contains '(subpath "/private/var/folders")' "$profile" "profile broad var folders"
}

test_gomodcache_must_stay_under_home
test_env_filter_rejects_secrets
test_clean_env_keeps_direnv_and_drops_secrets
test_project_temp_dir_is_per_project_and_under_home
test_managed_dir_rejects_symlink_escape
test_plugin_write_deny_rule
test_profile_uses_project_temp_only

printf 'ai-sandbox tests passed\n'
