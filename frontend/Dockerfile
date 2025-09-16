# --- build stage (unchanged except ensure fallback dirs exist) ---
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --silent; elif [ -f yarn.lock ]; then npm ci --silent || true; else npm install --silent; fi

COPY . .

ARG VITE_SERVER_URL=/api
ARG VITE_NEWS_INTERVAL_IN_MIN=5
ARG DEBUG_BUILD=false
ENV VITE_SERVER_URL=${VITE_SERVER_URL}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}
ENV DEBUG_BUILD=${DEBUG_BUILD}

RUN npm run build

# Ensure expected output directories exist so final-stage COPY never fails
RUN mkdir -p /app/backend/public/app /app/dist || true


# --- runtime stage ---
FROM nginx:1.29.1-alpine AS runtime

# Clean webroot
RUN rm -rf /usr/share/nginx/html/*

# Copy build outputs to temporary directories (do not write directly into the real webroot)
COPY --from=build /app/backend/public/app/ /usr/share/nginx/html-preferred/
COPY --from=build /app/dist/ /usr/share/nginx/html-fallback/

# Merge into real webroot without overwriting preferred files.
# We copy all preferred files first, then copy fallback files only if they don't already exist.
RUN mkdir -p /usr/share/nginx/html && \
    # copy preferred (preserve structure)
    if [ -d /usr/share/nginx/html-preferred ]; then \
      cp -a /usr/share/nginx/html-preferred/. /usr/share/nginx/html/ || true; \
    fi && \
    # copy fallback but don't overwrite existing files
    if [ -d /usr/share/nginx/html-fallback ]; then \
      for f in /usr/share/nginx/html-fallback/*; do \
        [ ! -e "$f" ] && continue; \
        dest="/usr/share/nginx/html/$(basename "$f")"; \
        if [ -e "$dest" ]; then \
          # if dest exists, we skip to avoid overwriting (preferred wins) - but still merge directories
          if [ -d "$f" ] && [ -d "$dest" ]; then \
            cp -a "$f/." "$dest/" || true; \
          fi; \
        else \
          cp -a "$f" "$dest" || true; \
        fi; \
      done; \
    fi && \
    rm -rf /usr/share/nginx/html-preferred /usr/share/nginx/html-fallback || true

# Optional: copy custom nginx config if present in repo build context (src/nginx copied earlier by CI)
COPY nginx/ /etc/nginx/conf.d/  # no-op if folder doesn't exist

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
