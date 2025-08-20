# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps (dev deps are needed to build)
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

# Normalize build output to a fixed path we control (/static)
# Handles projects that output to: dist, build, public/app, frontend/dist, backend/public/app, etc.
RUN set -eux; \
    candidates="dist build public public/app frontend/dist backend/public/app"; \
    out=""; \
    for p in $candidates; do \
      if [ -d "/app/$p" ] && [ "$(ls -A "/app/$p")" ]; then out="/app/$p"; break; fi; \
    done; \
    if [ -z "$out" ]; then \
      echo "No build output found in: $candidates"; \
      echo "Top-level /app listing:"; ls -la /app; \
      echo "Searching for likely build dirs..."; \
      find /app -maxdepth 3 -type d \( -name dist -o -name build -o -path '*/public/app' \) -print; \
      exit 1; \
    fi; \
    mkdir -p /static && cp -R "$out"/. /static/

# ---- serve stage ----
FROM nginx:1.27-alpine
# The nginx:alpine image already has a non-root user 'nginx' (uid/gid 101)

# Copy static assets
COPY --from=build /static /usr/share/nginx/html

# Copy Nginx config template and entrypoint
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Nginx needs to write to these directories at runtime.
# We change their ownership to the 'nginx' user.
RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid && chown -R nginx:nginx /var/run/nginx.pid

# Switch to the non-root user
USER nginx

# Expose the new port
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]