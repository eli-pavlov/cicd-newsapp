# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps
COPY package*.json ./
RUN npm ci

# Build args passed from the workflow
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN
ENV VITE_SERVER_URL=$VITE_SERVER_URL
ENV VITE_NEWS_INTERVAL_IN_MIN=$VITE_NEWS_INTERVAL_IN_MIN

# Bring in the source repo content (the workflow sets context: ./src)
COPY . .

# Build the app
RUN npm run build

# --- Normalize build output to /app/dist ---
# Your app emits to backend/public/app (per Vite logs); normalize so the next stage is stable.
RUN set -eux; \
  if [ -d backend/public/app ]; then \
    mkdir -p dist && cp -a backend/public/app/. dist/; \
  elif [ -d public/app ]; then \
    mkdir -p dist && cp -a public/app/. dist/; \
  elif [ -d build ]; then \
    mv build dist; \
  elif [ -d dist ]; then \
    echo "dist exists already, ok"; \
  else \
    echo "ERROR: Could not find Vite output (backend/public/app, public/app, build, or dist)"; \
    ls -la; \
    exit 1; \
  fi

# ---- serve stage ----
FROM nginx:1.27-alpine
WORKDIR /app

# Clear default HTML
RUN rm -rf /usr/share/nginx/html/*

# Copy the normalized Vite output
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx reverse proxy config (workflow copies frontend/nginx/* into src/nginx/)
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
