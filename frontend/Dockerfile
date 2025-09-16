# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps (dev deps needed to build)
COPY package*.json ./
# If you commit package-lock.json, it will be picked up by the COPY above
RUN npm ci --silent

# Build-time config for Vite
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN
ENV VITE_SERVER_URL=${VITE_SERVER_URL:-/api}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN:-5}

# Bring in the source and build
COPY . .
RUN npm run build

# Normalize build output to a fixed path and fail loudly if nothing found
RUN set -eux; \
    candidates="dist build public public/app frontend/dist backend/public/app out build/dist dist/client"; \
    out=""; \
    for p in $candidates; do \
      if [ -d "/app/$p" ] && [ -n "$(ls -A /app/$p || true)" ]; then \
        out="/app/$p"; \
        break; \
      fi; \
    done; \
    if [ -z "$out" ]; then \
      echo "ERROR: No build output found in any of: $candidates"; \
      echo "Top-level /app listing:"; ls -la /app; \
      echo "Searching for likely build dirs..."; \
      find /app -maxdepth 3 -type d \( -name dist -o -name build -o -path '*/public/app' -o -name frontend -o -name out \) -print; \
      exit 1; \
    fi; \
    echo "Using build output: $out"; \
    mkdir -p /static; cp -a "$out/." /static/

# ---- serve stage ----
FROM nginx:1.27-alpine

# envsubst (used by entrypoint.sh) and small niceties
RUN apk add --no-cache gettext

# Remove default nginx welcome content so we don't accidentally serve it
RUN rm -rf /usr/share/nginx/html/*

# Copy static assets from build stage
COPY --from=build /static /usr/share/nginx/html

# Copy nginx template + entrypoint (expect these paths in repo)
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh

# Make entrypoint executable and fix ownership so nginx (non-root user) can read files
RUN chmod +x /entrypoint.sh \
 && chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
 && touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid

# Run nginx as the nginx user for safety
USER nginx

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
