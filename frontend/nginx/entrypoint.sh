#!/bin/sh
set -eu

NS="${POD_NAMESPACE:-default}"
: "${BACKEND_SERVICE_HOST:=backend.${NS}.svc.cluster.local}"
: "${BACKEND_SERVICE_PORT:=8080}"

envsubst '$BACKEND_SERVICE_HOST $BACKEND_SERVICE_PORT' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec "$@"
