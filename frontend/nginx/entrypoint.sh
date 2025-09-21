#!/bin/sh
set -eu

NS="${POD_NAMESPACE:-default}"
: "${BACKEND_SERVICE_HOST:=backend.${NS}.svc.cluster.local}"
: "${BACKEND_SERVICE_PORT:=8080}"

envsubst '$BACKEND_SERVICE_HOST $BACKEND_SERVICE_PORT' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf


# source build-time file if present and export the vars ---
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
# ensure readable
chmod 0644 "${ENV_JS_PATH}" || true


exec "$@"
