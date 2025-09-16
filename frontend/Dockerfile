# syntax=docker/dockerfile:1

########################################
# Build stage
########################################
ARG NODE_IMAGE=node:22-alpine
ARG DEBUG_BUILD=false
ARG VITE_SERVER_URL=/api
ARG VITE_NEWS_INTERVAL_IN_MIN=5

FROM ${NODE_IMAGE} AS build

# Make build-time args visible in this stage
ARG DEBUG_BUILD
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN

ENV VITE_SERVER_URL=${VITE_SERVER_URL}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}
ENV DEBUG_BUILD=${DEBUG_BUILD}

WORKDIR /app

# Install build dependencies early (cache friendly)
COPY package.json package-lock.json* yarn.lock* ./
# Use npm ci when package-lock present; fallback to npm install
RUN if [ -f package-lock.json ]; then npm ci --silent; else npm install --silent; fi

# Copy rest of source
COPY . .

# Run the frontend build
RUN npm run build

# Locate build output (robustly) and copy into /static
RUN set -eux; \
    candidates="dist build public public/app frontend/dist backend/public/app"; \
    out=""; \
    for p in $candidates; do \
      if [ -d "/app/$p" ]; then \
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
    if [ -z "$out" ]; then \
      out=$(find /app -type f -iname "index.html" -printf '%h\n' | head -n1 || true); \
    fi; \
    if [ -z "$out" ]; then \
      echo "ERROR: No build output found (no index.html). Looked in: $candidates"; \
      echo "Top-level /app listing:"; ls -la /app || true; \
      echo "Searching deeper for likely build dirs..."; find /app -maxdepth 4 -type d -print || true; \
      exit 1; \
    fi; \
    echo "Found build output at: $out"; \
    mkdir -p /static; \
    cp -a "$out"/. /static/; \
    # DEBUG dump controlled by clean comparison (no comments inside the quoted string!)
    if [ "x${DEBUG_BUILD}" = "xtrue" ]; then \
      echo "==== DEBUG_BUILD: listing /static (top 200 entries) ===="; \
      find /static -maxdepth 6 -type f -print | sed -n '1,200p' || true; \
      if [ -f /static/index.html ]; then \
        echo "==== DEBUG_BUILD: head of /static/index.html (first 200 lines) ===="; \
        sed -n '1,200p' /static/index.html || true; \
      else \
        echo "==== DEBUG_BUILD: no /static/index.html found ===="; \
      fi; \
    fi

########################################
# Runtime stage (nginx)
########################################
FROM nginx:1.29.1-alpine AS runtime

# Bring in optional entrypoint and nginx templates if you use them
# (These should exist in your repo's nginx/ directory; keep in sync with your repo)
COPY --from=build /static /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh

# Make entrypoint executable and set proper permissions
RUN chmod +x /entrypoint.sh \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /usr/share/nginx/html \
    && touch /var/run/nginx.pid && chown -R nginx:nginx /var/run/nginx.pid

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
