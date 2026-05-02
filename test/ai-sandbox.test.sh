#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

fake_bin="$tmp_dir/bin"
work_dir="$tmp_dir/project"
home_dir="$tmp_dir/home"
log_file="$tmp_dir/container.log"
mkdir -p "$fake_bin" "$work_dir" "$home_dir"
work_dir=$(cd "$work_dir" && pwd)

hash=$(printf '%s' "$work_dir" | md5 | cut -c1-12)
old_container_name="ai-sandbox-project-${hash}"
new_container_name="ai-sandbox-home-v2-project-${hash}"

cat >"$fake_bin/container" <<'FAKE'
#!/usr/bin/env bash

set -euo pipefail

command="$1"
printf '%s' "$command" >>"$AI_SANDBOX_TEST_LOG"
shift || true
for arg in "$@"; do
    printf ' %q' "$arg" >>"$AI_SANDBOX_TEST_LOG"
done
printf '\n' >>"$AI_SANDBOX_TEST_LOG"

case "$command" in
    ls)
        exit 0
        ;;
    system)
        exit 0
        ;;
    image)
        if [[ "${1:-}" == "list" ]]; then
            printf 'NAME TAG\n'
            printf 'ai-sandbox latest\n'
            exit 0
        fi
        ;;
    list)
        printf 'NAME\n'
        if [[ "${1:-}" == "-a" ]]; then
            printf '%s\n' "$AI_SANDBOX_OLD_CONTAINER_NAME"
        fi
        exit 0
        ;;
    build|create|start|exec|rm)
        exit 0
        ;;
esac

printf 'unexpected container command: %s\n' "$*" >&2
exit 1
FAKE
chmod +x "$fake_bin/container"

(
    cd "$work_dir"
    PATH="$fake_bin:$PATH" \
        HOME="$home_dir" \
        TERM=xterm-256color \
        AI_SANDBOX_TEST_LOG="$log_file" \
        AI_SANDBOX_OLD_CONTAINER_NAME="$old_container_name" \
        "$repo_dir/bin/ai-sandbox" -- --version >/"$tmp_dir/output.log" 2>&1
)

assert_logged() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$log_file"; then
        printf 'expected log to contain: %s\n' "$expected" >&2
        printf 'actual log:\n' >&2
        cat "$log_file" >&2
        exit 1
    fi
}

assert_logged "build -f ${repo_dir}/bin/Dockerfile.ai-sandbox -t ai-sandbox:home-v2"
assert_logged "create --name ${new_container_name}"

printf 'ai-sandbox tests passed\n'
