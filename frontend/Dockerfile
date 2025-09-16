# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

ARG DEBUG_BUILD=false
ENV DEBUG_BUILD=${DEBUG_BUILD}

# Install deps (dev deps are needed to build)
# copy lockfile if present for reproducible installs
COPY package*.json ./
RUN npm ci

# Build-time config for Vite
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN
ENV VITE_SERVER_URL=$VITE_SERVER_URL
ENV VITE_NEWS_INTERVAL_IN_MIN=$VITE_NEWS_INTERVAL_IN_MIN

# Bring in the source and build
COPY . .
RUN npm run build

# Find the actual build output directory (robust search, require index.html)
RUN set -eux; \
    candidates="dist build public public/app frontend/dist backend/public/app"; \
    out=""; \
    for p in $candidates; do \
      if [ -d "/app/$p" ]; then \
        # only select this candidate if it contains an HTML entrypoint
        if find "/app/$p" -maxdepth 2 -type f \( -iname "index.html" -o -iname "index.htm" \) -print -quit >/dev/null 2>&1; then \
          if [ "$(ls -A "/app/$p" 2>/dev/null || true)" ]; then \
            out="/app/$p"; \
            break; \
          fi; \
        else \
          echo "Skipping /app/$p (no index.html found)"; \
        fi; \
      fi; \
    done; \
    # fallback: search the tree for any index.html produced by the build and use its parent dir
    if [ -z "$out" ]; then \
      out=$(find /app -type f -iname "index.html" -printf '%h\n' | head -n1 || true); \
    fi; \
    if [ -z "$out" ]; then \
      echo "ERROR: No build output found (no index.html). Looked in: $candidates"; \
      echo "Top-level /app listing:"; ls -la /app || true; \
      echo "Searching deeper for likely build dirs..."; \
      find /app -maxdepth 4 -type d -print || true; \
      exit 1; \
    fi; \
    echo "Found build output at: $out"; \
    mkdir -p /static; \
    cp -a "$out"/. /static/; \
    if [ "x$DEBUG_BUILD" = "xtrue" ]; then \
      echo "==== DEBUG_BUILD: listing /static (top 200 entries) ===="; \
      find /static -maxdepth 6 -type f -print | sed -n '1,200p' || true; \
      if [ -f /static/index.html ]; then \
        echo "==== DEBUG_BUILD: head of /static/index.html (first 200 lines) ===="; \
        sed -n '1,200p' /static/index.html || true; \
      else \
        echo "==== DEBUG_BUILD: no /static/index.html found ===="; \
      fi; \
    fi


# ---- serve stage ----
FROM nginx:1.29.1-alpine

# envsubst used by entrypoint.sh
RUN apk add --no-cache gettext

# Copy static assets
COPY --from=build /static /usr/share/nginx/html

# Copy Nginx config template and entrypoint
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh

# Ensure entrypoint and nginx state are writeable where needed
RUN chmod +x /entrypoint.sh \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /usr/share/nginx/html \
    && touch /var/run/nginx.pid && chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
