#!/bin/sh
# ---------------------------------------------------------------------
# Entrypoint for frontend nginx container.
# Purpose:
# - Substitute runtime backend host/port into nginx config template.
# - Load build metadata (if present) and export into the container env.
# - Generate a small `env.js` that client-side code can read to learn runtime vars.
# 
# Important notes (do not change here — informational):
# - This script runs as container ENTRYPOINT. It must be fast and idempotent.
# - Anything written to env.js is readable by the browser — do NOT place secrets here.
# - Keep the shebang as first line so the container runtime executes this correctly.
# ---------------------------------------------------------------------

set -eu

# Use POD_NAMESPACE if provided by the environment (Kubernetes Downward API), otherwise default to "default".
NS="${POD_NAMESPACE:-default}"
# Provide sensible defaults for backend host/port; allow overriding via env.
: "${BACKEND_SERVICE_HOST:=backend.${NS}.svc.cluster.local}"
: "${BACKEND_SERVICE_PORT:=8080}"

# Substitute only the listed variables into the nginx template.
# envsubst will replace $BACKEND_SERVICE_HOST and $BACKEND_SERVICE_PORT in the template.
# Limiting the substituted vars prevents unintended replacement of other tokens.
envsubst '$BACKEND_SERVICE_HOST $BACKEND_SERVICE_PORT' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf


# ---------------------------------------------------------------------
# Source build-time file if present and export the vars
# - BUILD_INFO_FILE is produced by the build stage and copied into the runtime image.
# - This block reads KEY=VALUE lines and exports them into the environment.
# - The code intentionally ignores empty lines and lines starting with '#' (comments).
# - It supports values that contain spaces (reads value using cut -f2-).
# ---------------------------------------------------------------------
BUILD_INFO_FILE="/etc/app/build-info.env"
if [ -f "${BUILD_INFO_FILE}" ]; then
  # read lines like KEY=VALUE and export them safely (ignore empty/comment lines)
  # this handles values with spaces as well
  while IFS= read -r line || [ -n "$line" ]; do
    # skip blank and comment lines
    case "$line" in
      ''|\#*) continue ;;
    esac
    key=$(printf '%s' "$line" | cut -d= -f1)
    value=$(printf '%s' "$line" | cut -d= -f2-)
    # export into the environment
    export "$key"="$value"
  done < "${BUILD_INFO_FILE}"
fi

# ---------------------------------------------------------------------
# Create a small env.js in the webroot exposing a controlled set of runtime
# variables to client-side JavaScript.
#
# Security reminder:
# - Anything written to env.js is public. Do NOT include secrets or private info.
# - Prefer only operational metadata (git commit, branch, service host/port).
# ---------------------------------------------------------------------
ENV_JS_PATH="/usr/share/nginx/html/env.js"
cat > "${ENV_JS_PATH}" <<EOF
// generated at container start - safe to read by client code
window.__APP_ENV = {
  VITE_FRONTEND_GIT_BRANCH: "${VITE_FRONTEND_GIT_BRANCH:-}",
  VITE_FRONTEND_GIT_COMMIT: "${VITE_FRONTEND_GIT_COMMIT:-}",
  BACKEND_SERVICE_HOST: "${BACKEND_SERVICE_HOST:-}",
  BACKEND_SERVICE_PORT: "${BACKEND_SERVICE_PORT:-}"
};
EOF
# Ensure the file is world-readable so nginx can serve it; ignore chmod errors to be robust.
chmod 0644 "${ENV_JS_PATH}" || true


# ---------------------------------------------------------------------
# Exec the original command (passed as arguments to the entrypoint).
# Using `exec` replaces the shell process with the command so signals (SIGTERM)
# are forwarded correctly to the main process (nginx).
# ---------------------------------------------------------------------
exec "$@"
