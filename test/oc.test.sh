#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gh_bin=$(command -v gh 2>/dev/null || true)
[[ -n "$gh_bin" ]] || { printf 'gh is required for oc tests\n' >&2; exit 1; }
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/oc-test.XXXXXX")

fake_bin="$tmp_dir/bin"
home_dir="$tmp_dir/home"
work_dir="$tmp_dir/workspace"
outside_dir="$tmp_dir/outside"
go_mod_dir="$tmp_dir/go/pkg/mod"
output_file="$tmp_dir/output.log"
failure_log="$output_file"

cleanup() {
    local status=$?
    if [[ $status -ne 0 && -f "$failure_log" ]]; then
        printf 'oc output before failure:\n' >&2
        cat "$failure_log" >&2
    fi
    rm -rf "$tmp_dir"
    exit "$status"
}
trap cleanup EXIT

mkdir -p "$fake_bin" "$home_dir" "$work_dir" "$outside_dir" "$go_mod_dir"
printf 'go-module-readable\n' >"$go_mod_dir/probe.txt"
printf 'path-readable\n' >"$fake_bin/path-probe.txt"
mkdir -p "$home_dir/.config/opencode"
printf '[user]\n\tname = Sandbox Test\n\temail = sandbox@example.com\n' >"$home_dir/.gitconfig"
printf 'config-target-readable\n' >"$outside_dir/config-target.txt"
printf 'config-sibling-private\n' >"$outside_dir/config-sibling.txt"
ln -s "$outside_dir/config-target.txt" "$home_dir/.config/opencode/config-link"
cat >"$work_dir/heredoc-probe.zsh" <<'ZSH'
#!/bin/zsh

value=$(cat <<'EOF'
heredoc-ok
EOF
)
[[ "$value" == "heredoc-ok" ]]
ZSH
chmod +x "$work_dir/heredoc-probe.zsh"
for private_dir in \
    "$home_dir/.krew" \
    "$home_dir/.lmstudio" \
    "$home_dir/.local/share/mise" \
    "$home_dir/.opencode"; do
    mkdir -p "$private_dir"
    printf 'private\n' >"$private_dir/private.txt"
done
mkdir -p "$home_dir/.opencode/bin"

cat >"$fake_bin/opencode" <<'FAKE'
#!/bin/bash

set -euo pipefail

probe_outside_write() {
    if (printf 'outside-write\n' >"$OC_SANDBOX_TEST_OUTSIDE") 2>/dev/null; then
        printf 'outside-write=allowed\n'
    else
        printf 'outside-write=blocked\n'
    fi
}

probe_private_read() {
    local label=$1
    local path=$2

    if IFS= read -r _ <"$path" 2>/dev/null; then
        printf '%s-read=allowed\n' "$label"
    else
        printf '%s-read=blocked\n' "$label"
    fi
}

if [[ "${1:-}" == "commit-probe" ]]; then
    git commit --allow-empty -m oc-test >/dev/null
    printf 'git-commit=ok\n'
    probe_outside_write
    exit 0
fi

if [[ "${1:-}" == "tls-probe" ]]; then
    tls_output=""
    if ! tls_output=$(GH_TOKEN=invalid "$OC_SANDBOX_TEST_GH" api graphql -f 'query={__typename}' 2>&1); then
        :
    fi
    case "$tls_output" in
        *"HTTP 401"*|*"Bad credentials"*) printf 'tls-validation=ok\n' ;;
        *) printf 'tls-validation=failed: %s\n' "$tls_output" ;;
    esac
    exit 0
fi

if [[ "${1:-}" == "signal-probe" ]]; then
    if kill -0 "$PPID" 2>/dev/null; then
        printf 'parent-signal=allowed\n'
    else
        printf 'parent-signal=blocked\n'
    fi
    exit 0
fi

printf 'arg-count=%s\n' "$#"
index=0
for arg in "$@"; do
    printf 'arg-%s=%s\n' "$index" "$arg"
    index=$((index + 1))
done

case "${OPENCODE_CONFIG_CONTENT:-}" in
    *'"permission"'*) printf 'config-content=present\n' ;;
    *) printf 'config-content=missing\n' ;;
esac

printf 'tmpdir=%s\n' "$TMPDIR"
printf 'npm-cache=%s\n' "$NPM_CONFIG_CACHE"
printf 'workspace-write\n' >"$PWD/workspace-write.txt"
printf 'temp-write\n' >"$TMPDIR/temp-write.txt"
printf 'cache-write\n' >"$XDG_CACHE_HOME/write-probe.txt"
mkdir -p "$XDG_CACHE_HOME/uv"
printf 'uv-cache-write\n' >"$XDG_CACHE_HOME/uv/write-probe.txt"
if mkdir -p "$HOME/Library/Caches/golangci-lint" 2>/dev/null &&
    (printf 'golangci-lint-cache-write\n' >"$HOME/Library/Caches/golangci-lint/write-probe.txt") 2>/dev/null; then
    printf 'macos-cache-write=allowed\n'
else
    printf 'macos-cache-write=blocked\n'
fi
if (printf 'opencode-install-write\n' >"$HOME/.opencode/bin/write-probe.txt") 2>/dev/null; then
    printf 'opencode-install-write=allowed\n'
else
    printf 'opencode-install-write=blocked\n'
fi

if IFS= read -r _ </private/etc/hosts 2>/dev/null; then
    printf 'private-etc-read=allowed\n'
else
    printf 'private-etc-read=blocked\n'
fi
if /bin/ls /Library/Preferences >/dev/null 2>&1; then
    printf 'library-preferences-read=allowed\n'
else
    printf 'library-preferences-read=blocked\n'
fi
probe_private_read config-sibling "$OC_SANDBOX_TEST_CONFIG_SIBLING"
probe_private_read krew-private "$HOME/.krew/private.txt"
probe_private_read lmstudio-private "$HOME/.lmstudio/private.txt"
probe_private_read mise-private "$HOME/.local/share/mise/private.txt"
probe_private_read opencode-private "$HOME/.opencode/private.txt"

if /usr/bin/ssh -F /dev/null -G localhost >/dev/null 2>&1; then
    printf 'ssh-user-lookup=allowed\n'
else
    printf 'ssh-user-lookup=blocked\n'
fi

for root in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"; do
    mkdir -p "$root/opencode"
    printf 'opencode-write\n' >"$root/opencode/write-probe.txt"
done

IFS= read -r config_link_value <"$OC_SANDBOX_TEST_CONFIG_LINK"
printf 'config-link-read=%s\n' "$config_link_value"
if (printf 'config-link-write\n' >"$OC_SANDBOX_TEST_CONFIG_LINK") 2>/dev/null; then
    printf 'config-link-write=allowed\n'
else
    printf 'config-link-write=blocked\n'
fi
probe_outside_write

if /bin/zsh "$PWD/heredoc-probe.zsh"; then
    printf 'zsh-heredoc=allowed\n'
else
    printf 'zsh-heredoc=blocked\n'
fi

IFS= read -r go_value <"$GOMODCACHE/probe.txt"
IFS= read -r path_value <"$(dirname "$0")/path-probe.txt"
printf 'go-read=%s\n' "$go_value"
printf 'path-read=%s\n' "$path_value"
if (printf 'go-module-write\n' >"$GOMODCACHE/write-probe.txt") 2>/dev/null; then
    printf 'go-module-write=allowed\n'
else
    printf 'go-module-write=blocked\n'
fi
FAKE
chmod +x "$fake_bin/opencode"

assert_contains() {
    local file="$1"
    local expected="$2"

    if ! grep -Fq -- "$expected" "$file"; then
        printf 'expected output to contain: %s\n' "$expected" >&2
        printf 'actual output:\n' >&2
        cat "$file" >&2
        exit 1
    fi
}

(
    cd "$work_dir"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        OC_SANDBOX_TEST_CONFIG_LINK="$home_dir/.config/opencode/config-link" \
        OC_SANDBOX_TEST_CONFIG_SIBLING="$outside_dir/config-sibling.txt" \
        OC_SANDBOX_TEST_OUTSIDE="$outside_dir/blocked.txt" \
        "$repo_dir/bin/oc" probe "two words" >"$output_file" 2>&1
)

assert_contains "$output_file" "arg-count=2"
assert_contains "$output_file" "arg-0=probe"
assert_contains "$output_file" "arg-1=two words"
assert_contains "$output_file" "config-content=present"
assert_contains "$output_file" "npm-cache=$home_dir/.cache/npm"
assert_contains "$output_file" "config-link-read=config-target-readable"
assert_contains "$output_file" "config-link-write=blocked"
assert_contains "$output_file" "macos-cache-write=allowed"
assert_contains "$output_file" "opencode-install-write=allowed"
assert_contains "$output_file" "private-etc-read=allowed"
assert_contains "$output_file" "library-preferences-read=allowed"
assert_contains "$output_file" "config-sibling-read=allowed"
assert_contains "$output_file" "krew-private-read=allowed"
assert_contains "$output_file" "lmstudio-private-read=allowed"
assert_contains "$output_file" "mise-private-read=allowed"
assert_contains "$output_file" "opencode-private-read=allowed"
assert_contains "$output_file" "ssh-user-lookup=allowed"
assert_contains "$output_file" "outside-write=blocked"
assert_contains "$output_file" "zsh-heredoc=allowed"
assert_contains "$output_file" "go-read=go-module-readable"
assert_contains "$output_file" "go-module-write=allowed"
assert_contains "$output_file" "path-read=path-readable"

[[ -f "$work_dir/workspace-write.txt" ]]
[[ -f "$home_dir/.config/opencode/write-probe.txt" ]]
[[ -f "$home_dir/.cache/write-probe.txt" ]]
[[ -f "$home_dir/.cache/opencode/write-probe.txt" ]]
[[ -f "$home_dir/.cache/uv/write-probe.txt" ]]
[[ -f "$home_dir/Library/Caches/golangci-lint/write-probe.txt" ]]
[[ -f "$home_dir/.local/share/opencode/write-probe.txt" ]]
[[ -f "$home_dir/.local/state/opencode/write-probe.txt" ]]
[[ -f "$home_dir/.opencode/bin/write-probe.txt" ]]
[[ -f "$go_mod_dir/write-probe.txt" ]]
[[ ! -e "$outside_dir/blocked.txt" ]]
IFS= read -r config_target_value <"$outside_dir/config-target.txt"
[[ "$config_target_value" == "config-target-readable" ]]

sandbox_tmp=$(grep '^tmpdir=' "$output_file" | cut -d= -f2-)
[[ "$sandbox_tmp" == *"oc-sandbox-"* ]]
[[ ! -e "$sandbox_tmp" ]]

tls_output="$tmp_dir/tls-output.log"
failure_log="$tls_output"
(
    cd "$work_dir"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        OC_SANDBOX_TEST_GH="$gh_bin" \
        "$repo_dir/bin/oc" tls-probe >"$tls_output" 2>&1
)
assert_contains "$tls_output" "tls-validation=ok"

signal_output="$tmp_dir/signal-output.log"
failure_log="$signal_output"
(
    cd "$work_dir"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        "$repo_dir/bin/oc" signal-probe >"$signal_output" 2>&1
)
assert_contains "$signal_output" "parent-signal=allowed"

bypass_output="$tmp_dir/bypass-output.log"
failure_log="$bypass_output"
(
    cd "$work_dir"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        OPENCODE_CONFIG_CONTENT='' \
        OC_SANDBOX_TEST_CONFIG_LINK="$home_dir/.config/opencode/config-link" \
        OC_SANDBOX_TEST_CONFIG_SIBLING="$outside_dir/config-sibling.txt" \
        OC_SANDBOX_TEST_OUTSIDE="$outside_dir/bypass.txt" \
        "$repo_dir/bin/oc" --without-sandbox probe "without sandbox" >"$bypass_output" 2>&1
)
assert_contains "$bypass_output" "arg-count=2"
assert_contains "$bypass_output" "arg-0=probe"
assert_contains "$bypass_output" "arg-1=without sandbox"
assert_contains "$bypass_output" "config-content=missing"
assert_contains "$bypass_output" "outside-write=allowed"
[[ -f "$outside_dir/bypass.txt" ]]

pass_output="$tmp_dir/pass-output.log"
failure_log="$pass_output"
(
    cd "$work_dir"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        OC_SANDBOX_TEST_CONFIG_LINK="$home_dir/.config/opencode/config-link" \
        OC_SANDBOX_TEST_CONFIG_SIBLING="$outside_dir/config-sibling.txt" \
        OC_SANDBOX_TEST_OUTSIDE="$outside_dir/blocked.txt" \
        "$repo_dir/bin/oc" -- --help >"$pass_output" 2>&1
)
assert_contains "$pass_output" "arg-0=--help"

help_output="$tmp_dir/help.log"
failure_log="$help_output"
"$repo_dir/bin/oc" --help >"$help_output"
assert_contains "$help_output" "Usage: oc"

main_repo="$tmp_dir/main-repo"
linked_worktree="$tmp_dir/linked-worktree"
/usr/bin/git init -q "$main_repo"
printf 'initial\n' >"$main_repo/README.md"
HOME="$home_dir" /usr/bin/git -C "$main_repo" add README.md
HOME="$home_dir" /usr/bin/git -C "$main_repo" commit -qm initial
/usr/bin/git -C "$main_repo" worktree add -qb linked-test "$linked_worktree"

commit_output="$tmp_dir/commit.log"
failure_log="$commit_output"
(
    cd "$linked_worktree"
    PATH="$fake_bin:/usr/bin:/bin" \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        GOMODCACHE="$go_mod_dir" \
        OC_SANDBOX_TEST_OUTSIDE="$main_repo/README.md" \
        "$repo_dir/bin/oc" commit-probe >"$commit_output" 2>&1
)
assert_contains "$commit_output" "git-commit=ok"
assert_contains "$commit_output" "outside-write=blocked"
IFS= read -r main_readme_value <"$main_repo/README.md"
[[ "$main_readme_value" == "initial" ]]

printf 'oc tests passed\n'
