#!/usr/bin/env bash

# Sourced by agent launchers. The caller supplies agent-specific writable paths.
declare -a sandbox_write_roots=()
declare -a sandbox_write_files=()
declare -a sandbox_write_sidecars=()
sandbox_tmp=""

sandbox_die() {
    printf '%s: %s\n' "$sandbox_name" "$*" >&2
    exit 1
}

sandbox_allow_dir() {
    local candidate resolved existing
    candidate=$1
    [[ -d "$candidate" ]] || return 0
    resolved=$(cd -P "$candidate" && pwd)
    for existing in "${sandbox_write_roots[@]:-}"; do
        [[ "$existing" == "$resolved" ]] && return 0
    done
    sandbox_write_roots+=("$resolved")
}

sandbox_allow_file() {
    local candidate parent resolved existing target
    candidate=$1
    [[ "$candidate" == /* ]] || sandbox_die "writable file path must be absolute: $candidate"
    parent=$(cd -P "$(dirname "$candidate")" && pwd)
    resolved="$parent/$(basename "$candidate")"
    # Resolve file symlinks, too: Seatbelt checks the target, not just its link.
    if [[ -L "$resolved" && ! -e "$resolved" ]]; then
        target=$(readlink "$resolved")
        [[ "$target" == /* ]] || target="$parent/$target"
        parent=$(cd -P "$(dirname "$target")" && pwd)
        resolved="$parent/$(basename "$target")"
    elif [[ -e "$resolved" ]]; then
        resolved=$(realpath "$resolved")
    fi
    for existing in "${sandbox_write_files[@]:-}"; do
        [[ "$existing" == "$resolved" ]] && return 0
    done
    sandbox_write_files+=("$resolved")
}

sandbox_allow_sidecars() {
    local file=$1
    sandbox_allow_file "$file"
    sandbox_write_sidecars+=("${sandbox_write_files[${#sandbox_write_files[@]}-1]}")
}

sandbox_cleanup() {
    if [[ -n "$sandbox_tmp" ]]; then
        rm -rf -- "$sandbox_tmp"
    fi
}

sandbox_playwright_shim() {
    local playwright_cli_bin
    playwright_cli_bin=${OC_PLAYWRIGHT_CLI_BIN:-}
    if [[ ! -x "$playwright_cli_bin" ]]; then
        playwright_cli_bin=$(command -v playwright-cli 2>/dev/null || true)
    fi
    [[ -n "$playwright_cli_bin" ]] || return 0
    playwright_cli_bin=$(realpath "$playwright_cli_bin")
    export OC_PLAYWRIGHT_CLI_BIN="$playwright_cli_bin"
    cat >"$sandbox_tmp/bin/playwright-cli" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    ""|-h|--help|-V|--version)
        exec "$OC_PLAYWRIGHT_CLI_BIN" "$@"
        ;;
esac

cli_command=""
for arg in "$@"; do
    if [[ "$arg" != -* ]]; then
        cli_command=$arg
        break
    fi
done

case "$cli_command" in
    attach|close|close-all|delete-data|detach|install|install-browser|kill-all|list)
        exec "$OC_PLAYWRIGHT_CLI_BIN" "$@"
        ;;
esac

cdp_endpoint=http://127.0.0.1:9222
if ! curl --connect-timeout 1 --max-time 2 -fsS "$cdp_endpoint/json/version" >/dev/null 2>&1; then
    printf 'playwright-cli: Chrome CDP is unavailable at %s.\n' "$cdp_endpoint" >&2
    printf 'Run `chrome-cdp` in a terminal outside %s, then retry.\n' "$SANDBOX_AGENT_NAME" >&2
    exit 1
fi

exec "$OC_PLAYWRIGHT_CLI_BIN" "$@"
EOF
    chmod +x "$sandbox_tmp/bin/playwright-cli"
    export PATH="$sandbox_tmp/bin:$PATH"
}

sandbox_init() {
    sandbox_name=$1
    [[ "$(uname -s)" == "Darwin" ]] || sandbox_die "sandbox-exec is only available on macOS"
    [[ -x /usr/bin/sandbox-exec ]] || sandbox_die "/usr/bin/sandbox-exec is unavailable"

    sandbox_work_dir=$(pwd -P)
    local root host_tmp work_hash git_common_dir go_path go_bin go_mod_cache developer_dir
    local xdg_config_home xdg_cache_home xdg_data_home xdg_state_home zoxide_data_dir
    xdg_config_home=${XDG_CONFIG_HOME:-$HOME/.config}
    xdg_cache_home=${XDG_CACHE_HOME:-$HOME/.cache}
    xdg_data_home=${XDG_DATA_HOME:-$HOME/.local/share}
    xdg_state_home=${XDG_STATE_HOME:-$HOME/.local/state}
    for root in "$xdg_config_home" "$xdg_cache_home" "$xdg_data_home" "$xdg_state_home"; do
        [[ "$root" == /* ]] || sandbox_die "XDG directories must be absolute: $root"
    done
    SANDBOX_MACOS_CACHE_DIR="$HOME/Library/Caches"
    mkdir -p "$SANDBOX_MACOS_CACHE_DIR" "$xdg_config_home" "$xdg_cache_home" "$xdg_data_home" "$xdg_state_home"
    SANDBOX_MACOS_CACHE_DIR=$(cd -P "$SANDBOX_MACOS_CACHE_DIR" && pwd)
    xdg_config_home=$(cd -P "$xdg_config_home" && pwd)
    xdg_cache_home=$(cd -P "$xdg_cache_home" && pwd)
    xdg_data_home=$(cd -P "$xdg_data_home" && pwd)
    xdg_state_home=$(cd -P "$xdg_state_home" && pwd)

    host_tmp=${TMPDIR:-/tmp}
    [[ "$host_tmp" == /* && -d "$host_tmp" ]] || sandbox_die "TMPDIR must be an existing absolute directory"
    work_hash=$(printf '%s' "$sandbox_work_dir" | /sbin/md5 -q | cut -c1-12)
    sandbox_tmp=$(mktemp -d "${host_tmp%/}/${sandbox_name}-sandbox-${work_hash}.XXXXXX")
    sandbox_tmp=$(cd -P "$sandbox_tmp" && pwd)
    trap sandbox_cleanup EXIT
    mkdir -p "$sandbox_tmp/ansible" "$sandbox_tmp/bin" "$sandbox_tmp/go-build" "$sandbox_tmp/go-tmp"

    export ANSIBLE_LOCAL_TEMP="$sandbox_tmp/ansible"
    export TMPDIR="$sandbox_tmp" TMP="$sandbox_tmp" TEMP="$sandbox_tmp" TMPPREFIX="$sandbox_tmp/zsh"
    export PWTEST_SOCKETS_DIR="$SANDBOX_MACOS_CACHE_DIR/playwright-cli"
    export PLAYWRIGHT_MCP_CDP_ENDPOINT=http://127.0.0.1:9222 PLAYWRIGHT_MCP_BROWSER=chromium
    export GOCACHE="$sandbox_tmp/go-build" GOTMPDIR="$sandbox_tmp/go-tmp"
    export XDG_CONFIG_HOME="$xdg_config_home" XDG_CACHE_HOME="$xdg_cache_home"
    export XDG_DATA_HOME="$xdg_data_home" XDG_STATE_HOME="$xdg_state_home"
    export NPM_CONFIG_CACHE="$xdg_cache_home/npm"
    export SANDBOX_AGENT_NAME="$sandbox_name"
    sandbox_playwright_shim

    sandbox_allow_dir "$sandbox_work_dir"
    sandbox_allow_dir "$sandbox_tmp"
    sandbox_allow_dir "$xdg_cache_home"
    sandbox_allow_dir "$SANDBOX_MACOS_CACHE_DIR"
    zoxide_data_dir="$HOME/Library/Application Support/zoxide"
    mkdir -p "$zoxide_data_dir"
    sandbox_allow_dir "$zoxide_data_dir"

    git_common_dir=$(git -C "$sandbox_work_dir" rev-parse --git-common-dir 2>/dev/null || true)
    if [[ -n "$git_common_dir" ]]; then
        [[ "$git_common_dir" == /* ]] || git_common_dir="$sandbox_work_dir/$git_common_dir"
        sandbox_allow_dir "$git_common_dir"
    fi

    go_path=${GOPATH:-$HOME/go}
    go_path=${go_path%%:*}
    go_bin=${GOBIN:-$go_path/bin}
    go_mod_cache=${GOMODCACHE:-$go_path/pkg/mod}
    if [[ -d "$go_path" || -d "$go_bin" || -d "$go_mod_cache" ]] || command -v go >/dev/null 2>&1; then
        mkdir -p "$go_path" "$go_bin" "$go_mod_cache"
        go_mod_cache=$(cd -P "$go_mod_cache" && pwd)
        export GOMODCACHE="$go_mod_cache"
        sandbox_allow_dir "$go_path"
        sandbox_allow_dir "$go_bin"
        sandbox_allow_dir "$go_mod_cache"
    fi

    developer_dir=$(/usr/bin/xcode-select -p 2>/dev/null || true)
    if [[ -n "$developer_dir" && -d "$developer_dir" ]]; then
        DEVELOPER_DIR=$(cd -P "$developer_dir" && pwd)
        export DEVELOPER_DIR
    fi
}

sandbox_regex_escape() {
    local text=$1 char escaped="" i
    for ((i=0; i<${#text}; i++)); do
        char=${text:i:1}
        case "$char" in
            '.'|"\\"|'+'|'*'|'?'|'^'|'$'|'('|')'|'['|']'|'{'|'}'|'|'|'"') escaped+="\\$char" ;;
            *) escaped+="$char" ;;
        esac
    done
    printf '%s' "$escaped"
}

sandbox_run() {
    local profile index key root file status escaped
    local -a definitions=()
    profile='(version 1)
(deny default)

(allow process-exec)
(allow process-fork)
; Agents can signal their process group (for example, when suspended).
(allow signal)
(allow process-info* (target same-sandbox))
(allow sysctl-read)

; Reads are unrestricted. Seatbelt enforces write isolation only.
(allow file-read* file-test-existence)
(allow file-map-executable)

; Terminal and inherited file descriptors.
(allow pseudo-tty)
(allow file-read-data file-test-existence file-write-data (subpath "/dev/fd"))
(allow file-read* file-write* file-ioctl (literal "/dev/ptmx"))
(allow file-read* file-write* (literal "/dev/null"))
(allow file-read* file-write* (literal "/dev/tty"))
(allow file-read-metadata (literal "/dev"))
(allow file-read* file-write* (regex #"^/dev/ttys[0-9]+$"))
(allow file-ioctl (regex #"^/dev/ttys[0-9]+$"))

; Network access is always enabled so agents can reach model providers.
(allow network-outbound)
(allow network-inbound)

; Native tools rely on macOS services; file writes remain constrained separately.
(allow mach-lookup)'

    index=0
    for root in "${sandbox_write_roots[@]:-}"; do
        [[ -n "$root" ]] || continue
        key="WRITABLE_ROOT_$index"
        profile+=$'\n'"(allow file-write* (subpath (param \"$key\")))"
        definitions+=("-D$key=$root")
        index=$((index + 1))
    done
    index=0
    for file in "${sandbox_write_files[@]:-}"; do
        [[ -n "$file" ]] || continue
        key="WRITABLE_FILE_$index"
        profile+=$'\n'"(allow file-write* (literal (param \"$key\")))"
        definitions+=("-D$key=$file")
        index=$((index + 1))
    done
    for file in "${sandbox_write_sidecars[@]:-}"; do
        [[ -n "$file" ]] || continue
        escaped=$(sandbox_regex_escape "$file")
        profile+=$'\n'"(allow file-write* (regex #\"^${escaped}\\.(tmp|lock)(\\..*)?\$\"))"
    done

    status=0
    /usr/bin/sandbox-exec -p "$profile" "${definitions[@]}" -- "$@" || status=$?
    return "$status"
}
