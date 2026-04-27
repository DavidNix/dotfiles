#!/usr/bin/env bash

set -euo pipefail

_ai_sandbox_die() {
    printf 'ai-sandbox: %s\n' "$*" >&2
    exit 1
}

_ai_sandbox_script_dir() {
    local source dir

    source="${BASH_SOURCE[0]}"
    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" == /* ]] || source="${dir}/${source}"
    done

    cd -P "$(dirname "$source")" && pwd
}

AI_SANDBOX_DIR="$(_ai_sandbox_script_dir)"
AI_SANDBOX_PROFILE_TEMPLATE="${AI_SANDBOX_DIR}/_ai-seatbelt.sb"

_ai_sandbox_realpath() {
    /usr/bin/python3 - "$1" <<'PY'
import os
import sys

print(os.path.realpath(sys.argv[1]))
PY
}

_ai_sandbox_path_dirname() {
    /usr/bin/python3 - "$1" <<'PY'
import os
import sys

print(os.path.dirname(os.path.abspath(sys.argv[1])))
PY
}

_ai_sandbox_prepare_managed_dir() {
    local target parent result

    target="$1"
    parent="$2"

    result="$(/usr/bin/python3 - "$target" "$parent" <<'PY'
import os
import sys

target = os.path.abspath(os.path.expanduser(sys.argv[1]))
parent = os.path.abspath(os.path.expanduser(sys.argv[2]))

def fail(message):
    print(message)
    sys.exit(1)

def is_under(path, root):
    try:
        return os.path.commonpath([path, root]) == root
    except ValueError:
        return False

os.makedirs(parent, exist_ok=True)

if os.path.realpath(parent) != parent:
    fail(f"managed parent contains a symlink: {parent}")

if not is_under(target, parent):
    fail(f"managed path is outside expected parent: {target}")

current = parent
relative = os.path.relpath(target, parent)
if relative != ".":
    for part in relative.split(os.sep):
        current = os.path.join(current, part)
        if os.path.lexists(current) and os.path.islink(current):
            fail(f"managed path contains a symlink: {current}")

os.makedirs(target, exist_ok=True)
real_target = os.path.realpath(target)

if not is_under(real_target, parent):
    fail(f"managed path resolves outside expected parent: {real_target}")

print(real_target)
PY
)" || _ai_sandbox_die "$result"

    printf '%s\n' "$result"
}

_ai_sandbox_prepare_user_dir() {
    _ai_sandbox_prepare_managed_dir "$1" "$HOME"
}

_ai_sandbox_project_temp_dir() {
    local project_dir

    project_dir="$1"
    /usr/bin/python3 - "$HOME" "$project_dir" <<'PY'
import hashlib
import os
import sys

home = sys.argv[1]
project = os.path.realpath(sys.argv[2])
digest = hashlib.sha256(project.encode()).hexdigest()[:24]
print(os.path.join(home, ".cache", "ai-sandbox", "tmp", digest))
PY
}

_ai_sandbox_env_name_allowed() {
    local name

    name="$1"

    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    case "$name" in
        SSH_AUTH_SOCK|SSH_AGENT_PID|GPG_AGENT_INFO|GPG_TTY|SUDO_*|BASH_FUNC_*|ZSH_FUNC_*)
            return 1
            ;;
        DIRENV_DIFF)
            return 1
            ;;
        *TOKEN*|*PASSWORD*|*PASSWD*|*SECRET*|*CREDENTIAL*|*PRIVATE*|*API_KEY*|*ACCESS_KEY*|*AUTH*|*COOKIE*|*SESSION*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

_ai_sandbox_emit_current_env() {
    local name value

    for name in "$@"; do
        value="${!name-}"
        [[ -n "$value" ]] || continue
        printf '%s=%s\n' "$name" "$value"
    done
}

_ai_sandbox_direnv_env() {
    local json status

    command -v direnv >/dev/null 2>&1 || return 0

    set +e
    json="$(direnv export json 2>/dev/null)"
    status=$?
    set -e

    [[ $status -eq 0 && -n "$json" ]] || return 0

    /usr/bin/python3 - "$json" <<'PY'
import json
import sys

try:
    values = json.loads(sys.argv[1])
except json.JSONDecodeError:
    sys.exit(0)

for name, value in values.items():
    if value is None:
        continue
    print(f"{name}={value}")
PY
}

_ai_sandbox_build_clean_env() {
    local tmp_dir gomodcache gocache_dir entry name value

    tmp_dir="$1"
    gomodcache="$2"
    gocache_dir="$3"
    shift 3

    printf 'HOME=%s\n' "$HOME"
    _ai_sandbox_emit_current_env \
        USER LOGNAME SHELL TERM TERM_PROGRAM COLORTERM LANG LC_ALL LC_CTYPE LC_MESSAGES TZ \
        NO_COLOR FORCE_COLOR CLICOLOR CLICOLOR_FORCE EDITOR VISUAL PAGER
    printf 'TMPDIR=%s\n' "$tmp_dir"
    printf 'TMP=%s\n' "$tmp_dir"
    printf 'TEMP=%s\n' "$tmp_dir"
    printf 'GOMODCACHE=%s\n' "$gomodcache"
    printf 'GOCACHE=%s\n' "$gocache_dir"

    for entry in "$@"; do
        [[ "$entry" == *=* ]] || continue
        name="${entry%%=*}"
        value="${entry#*=}"
        _ai_sandbox_env_name_allowed "$name" || continue
        case "$name" in
            HOME|PATH|TMPDIR|TMP|TEMP|GOMODCACHE|GOCACHE|USER|LOGNAME|SHELL)
                continue
                ;;
        esac
        printf '%s=%s\n' "$name" "$value"
    done
}

_ai_sandbox_sb_quote() {
    local value

    value=${1//\\/\\\\}
    value=${value//\"/\\\"}
    printf '"%s"' "$value"
}

_ai_sandbox_resolve_command() {
    local command_path

    command_path="$(command -v "$1" 2>/dev/null || true)"
    [[ -n "$command_path" ]] || _ai_sandbox_die "could not find '$1' in PATH"
    _ai_sandbox_realpath "$command_path"
}

_ai_sandbox_is_safe_path_dir() {
    case "$1" in
        /bin|/sbin|/usr/bin|/usr/sbin|/usr/local/bin|/usr/local/sbin)
            return 0
            ;;
        /opt/*|/System/Cryptexes/*|/var/run/com.apple.security.cryptexd/*)
            return 0
            ;;
        "$HOME"/.local/share/mise/installs/*/bin)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_ai_sandbox_append_path() {
    local dir current

    dir="$1"
    current="$2"

    if [[ -z "$current" ]]; then
        printf '%s' "$dir"
        return
    fi

    case ":$current:" in
        *":$dir:"*)
            printf '%s' "$current"
            ;;
        *)
            printf '%s:%s' "$current" "$dir"
            ;;
    esac
}

_ai_sandbox_build_path() {
    local sandbox_path dir
    local -a current_parts default_parts

    sandbox_path=""
    IFS=: read -r -a current_parts <<< "${PATH:-}"
    default_parts=(/opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin /usr/bin /bin /usr/sbin /sbin /System/Cryptexes/App/usr/bin)

    for dir in "${current_parts[@]}"; do
        [[ -n "$dir" && -d "$dir" ]] || continue
        if _ai_sandbox_is_safe_path_dir "$dir"; then
            sandbox_path="$(_ai_sandbox_append_path "$dir" "$sandbox_path")"
        fi
    done

    for dir in "${default_parts[@]}"; do
        [[ -d "$dir" ]] || continue
        sandbox_path="$(_ai_sandbox_append_path "$dir" "$sandbox_path")"
    done

    printf '%s\n' "$sandbox_path"
}

_ai_sandbox_build_metadata_rules() {
    /usr/bin/python3 - "$@" <<'PY'
import os
import sys

seen = set()

for raw_path in sys.argv[1:]:
    if not raw_path:
        continue
    path = os.path.realpath(raw_path)
    if not os.path.isabs(path):
        continue

    current = path
    while True:
        if current not in seen:
            seen.add(current)
            escaped = current.replace('\\', '\\\\').replace('"', '\\"')
            print(f'  (literal "{escaped}")')
        parent = os.path.dirname(current)
        if parent == current:
            break
        current = parent
PY
}

_ai_sandbox_render_profile() {
    local metadata_rules harness_rw_rules extra_exec_rules deny_rules template

    metadata_rules="$1"
    harness_rw_rules="$2"
    extra_exec_rules="$3"
    deny_rules="$4"

    template="$(<"$AI_SANDBOX_PROFILE_TEMPLATE")"
    template=${template//__AI_SANDBOX_METADATA_RULES__/$metadata_rules}
    template=${template//__AI_SANDBOX_HARNESS_RW_RULES__/$harness_rw_rules}
    template=${template//__AI_SANDBOX_EXTRA_EXEC_RULES__/$extra_exec_rules}
    template=${template//__AI_SANDBOX_DENY_RULES__/$deny_rules}
    printf '%s\n' "$template"
}

_ai_sandbox_build_deny_rules() {
    local raw_path path

    for raw_path in "$@"; do
        [[ -n "$raw_path" ]] || continue
        path="$(_ai_sandbox_realpath "$raw_path")"
        printf '(%s file-write* (subpath %s))\n' deny "$(_ai_sandbox_sb_quote "$path")"
    done
}

_ai_sandbox_default_gomodcache() {
    local gomodcache

    gomodcache="${GOMODCACHE:-}"
    if [[ -z "$gomodcache" ]] && command -v go >/dev/null 2>&1; then
        gomodcache="$(go env GOMODCACHE 2>/dev/null || true)"
    fi
    if [[ -z "$gomodcache" ]]; then
        gomodcache="$HOME/go/pkg/mod"
    fi

    _ai_sandbox_prepare_user_dir "$gomodcache"
}

_ai_sandbox_main() {
    local command_name project_dir real_bin gomodcache gocache_dir sandbox_path mise_installs_dir profile_file status tmp_dir tmp_parent gocache_parent
    local harness_path
    local metadata_rules harness_rw_rules extra_exec_rules deny_rules env_entry
    local -a harness_dirs harness_files exec_dirs env_vars deny_write_dirs metadata_paths args direnv_env clean_env

    command_name="$1"
    shift
    gocache_dir=""
    harness_dirs=()
    harness_files=()
    exec_dirs=()
    env_vars=()
    deny_write_dirs=()
    args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --harness-dir)
                harness_dirs+=("$2")
                shift 2
                ;;
            --harness-file)
                harness_files+=("$2")
                shift 2
                ;;
            --exec-dir)
                exec_dirs+=("$2")
                shift 2
                ;;
            --env)
                env_vars+=("$2")
                shift 2
                ;;
            --deny-write-dir)
                deny_write_dirs+=("$2")
                shift 2
                ;;
            --gocache-dir)
                gocache_dir="$2"
                shift 2
                ;;
            --)
                shift
                args=("$@")
                break
                ;;
            *)
                _ai_sandbox_die "unknown option '$1'"
                ;;
        esac
    done

    [[ -n "$gocache_dir" ]] || _ai_sandbox_die "missing --gocache-dir for ${command_name}"
    [[ -f "$AI_SANDBOX_PROFILE_TEMPLATE" ]] || _ai_sandbox_die "missing profile template at $AI_SANDBOX_PROFILE_TEMPLATE"

    project_dir="$(pwd -P)"
    real_bin="$(_ai_sandbox_resolve_command "$command_name")"
    gomodcache="$(_ai_sandbox_default_gomodcache)"
    gocache_parent="$(_ai_sandbox_path_dirname "$gocache_dir")"
    gocache_dir="$(_ai_sandbox_prepare_managed_dir "$gocache_dir" "$gocache_parent")"
    tmp_dir="$(_ai_sandbox_project_temp_dir "$project_dir")"
    tmp_parent="$(_ai_sandbox_path_dirname "$tmp_dir")"
    tmp_dir="$(_ai_sandbox_prepare_managed_dir "$tmp_dir" "$tmp_parent")"
    sandbox_path="$(_ai_sandbox_build_path)"
    mise_installs_dir="$(_ai_sandbox_realpath "$HOME/.local/share/mise/installs")"

    metadata_paths=("$project_dir" "$gomodcache" "$gocache_dir" "$tmp_dir" "$real_bin" "$mise_installs_dir")
    harness_rw_rules=""
    extra_exec_rules=""
    deny_rules=""

    for harness_path in "${harness_dirs[@]}"; do
        mkdir -p "$harness_path"
        harness_path="$(_ai_sandbox_realpath "$harness_path")"
        harness_rw_rules+="$(printf '(%s file-read* file-write* (subpath %s))\n' allow "$(_ai_sandbox_sb_quote "$harness_path")")"
        metadata_paths+=("$harness_path")
    done

    for harness_path in "${harness_files[@]}"; do
        mkdir -p "$(dirname "$harness_path")"
        harness_rw_rules+="$(printf '(%s file-read* file-write* (literal %s))\n' allow "$(_ai_sandbox_sb_quote "$harness_path")")"
        metadata_paths+=("$harness_path")
    done

    for harness_path in "${exec_dirs[@]}"; do
        harness_path="$(_ai_sandbox_realpath "$harness_path")"
        extra_exec_rules+="$(printf '  (subpath %s)\n' "$(_ai_sandbox_sb_quote "$harness_path")")"
        metadata_paths+=("$harness_path")
    done

    deny_rules="$(_ai_sandbox_build_deny_rules "${deny_write_dirs[@]}")"

    direnv_env=()
    while IFS= read -r env_entry; do
        direnv_env+=("$env_entry")
    done < <(_ai_sandbox_direnv_env)

    clean_env=("PATH=$sandbox_path")
    while IFS= read -r env_entry; do
        clean_env+=("$env_entry")
    done < <(_ai_sandbox_build_clean_env "$tmp_dir" "$gomodcache" "$gocache_dir" "${direnv_env[@]}" "${env_vars[@]}")

    metadata_rules="$(_ai_sandbox_build_metadata_rules "${metadata_paths[@]}")"
    profile_file="$(mktemp "/tmp/${command_name}-sandbox.XXXXXX.sb")"
    _ai_sandbox_render_profile "$metadata_rules" "$harness_rw_rules" "$extra_exec_rules" "$deny_rules" >"$profile_file"

    set +e
    sandbox-exec \
        -f "$profile_file" \
        -D "REAL_BIN=$real_bin" \
        -D "PROJECT_DIR=$project_dir" \
        -D "GOMODCACHE=$gomodcache" \
        -D "GOCACHE_DIR=$gocache_dir" \
        -D "TMP_DIR=$tmp_dir" \
        -D "MISE_INSTALLS_DIR=$mise_installs_dir" \
        /usr/bin/env -i \
        "${clean_env[@]}" \
        "$real_bin" \
        "${args[@]}"
    status=$?
    set -e

    rm -f "$profile_file"
    return "$status"
}
