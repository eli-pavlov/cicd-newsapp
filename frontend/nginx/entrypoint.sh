#!/bin/sh
set -eu
: "${BACKEND_SERVICE_HOST:=backend.backend.svc.cluster.local}"
: "${BACKEND_SERVICE_PORT:=8080}"

envsubst '$BACKEND_SERVICE_HOST $BACKEND_SERVICE_PORT' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec "$@"
