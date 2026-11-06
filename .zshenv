# Zsh reads this file for every shell, including non-interactive ones.
# Keep it to plain environment variables. PATH changes stay in .zshrc,
# because macOS /etc/zprofile runs path_helper after this file and reorders PATH.

# Point to Colima's docker socket
# Aaaaand back to Docker Desktop. Was getting perf issues with KinD using colima.
# export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# Make neovim default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# See: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# OpenAI CLI auth: pull the key from Keychain (item: openai-api-key, account: $USER).
# A manually exported OPENAI_API_KEY wins. Add the key with:
#   security add-generic-password -U -a "$USER" -s openai-api-key -w "YOUR_OPENAI_API_KEY"
export OPENAI_API_KEY="${OPENAI_API_KEY:-$(security find-generic-password -a "$USER" -s openai-api-key -w 2>/dev/null)}"

# PagerDuty MCP auth: pull the key from Keychain (item: pagerduty-mcp, account: $USER).
# Add the key with:
#   security add-generic-password -U -a "$USER" -s pagerduty-mcp -w "YOUR_PAGERDUTY_API_KEY"
export PAGERDUTY_USER_API_KEY="$(security find-generic-password -a "$USER" -s pagerduty-mcp -w 2>/dev/null)"
