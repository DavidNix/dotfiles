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
    local metadata_rules harness_rw_rules extra_exec_rules template

    metadata_rules="$1"
    harness_rw_rules="$2"
    extra_exec_rules="$3"

    template="$(<"$AI_SANDBOX_PROFILE_TEMPLATE")"
    template=${template//__AI_SANDBOX_METADATA_RULES__/$metadata_rules}
    template=${template//__AI_SANDBOX_HARNESS_RW_RULES__/$harness_rw_rules}
    template=${template//__AI_SANDBOX_EXTRA_EXEC_RULES__/$extra_exec_rules}
    printf '%s\n' "$template"
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

    mkdir -p "$gomodcache"
    _ai_sandbox_realpath "$gomodcache"
}

_ai_sandbox_main() {
    local command_name project_dir real_bin gomodcache gocache_dir sandbox_path mise_installs_dir profile_file status
    local harness_path
    local metadata_rules harness_rw_rules extra_exec_rules
    local -a harness_dirs harness_files exec_dirs env_vars metadata_paths args

    command_name="$1"
    shift
    gocache_dir=""
    harness_dirs=()
    harness_files=()
    exec_dirs=()
    env_vars=()
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
    mkdir -p "$gocache_dir"
    gocache_dir="$(_ai_sandbox_realpath "$gocache_dir")"
    sandbox_path="$(_ai_sandbox_build_path)"
    mise_installs_dir="$(_ai_sandbox_realpath "$HOME/.local/share/mise/installs")"

    metadata_paths=("$project_dir" "$gomodcache" "$gocache_dir" "$real_bin" "$mise_installs_dir")
    harness_rw_rules=""
    extra_exec_rules=""

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

    metadata_rules="$(_ai_sandbox_build_metadata_rules "${metadata_paths[@]}")"
    profile_file="$(mktemp "/tmp/${command_name}-sandbox.XXXXXX.sb")"
    _ai_sandbox_render_profile "$metadata_rules" "$harness_rw_rules" "$extra_exec_rules" >"$profile_file"

    set +e
    sandbox-exec \
        -f "$profile_file" \
        -D "REAL_BIN=$real_bin" \
        -D "PROJECT_DIR=$project_dir" \
        -D "GOMODCACHE=$gomodcache" \
        -D "GOCACHE_DIR=$gocache_dir" \
        -D "MISE_INSTALLS_DIR=$mise_installs_dir" \
        /usr/bin/env \
        "PATH=$sandbox_path" \
        "GOMODCACHE=$gomodcache" \
        "GOCACHE=$gocache_dir" \
        "${env_vars[@]}" \
        "$real_bin" \
        "${args[@]}"
    status=$?
    set -e

    rm -f "$profile_file"
    return "$status"
}
