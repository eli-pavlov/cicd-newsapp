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

node ./src/utils/git_info.js

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
RUN mkdir -p /usr/share/nginx/html && \
    if [ -d /usr/share/nginx/html-preferred ]; then \
      cp -a /usr/share/nginx/html-preferred/. /usr/share/nginx/html/ || true; \
    fi && \
    if [ -d /usr/share/nginx/html-fallback ]; then \
      for f in /usr/share/nginx/html-fallback/*; do \
        [ ! -e "$f" ] && continue; \
        dest="/usr/share/nginx/html/$(basename "$f")"; \
        if [ -e "$dest" ]; then \
          if [ -d "$f" ] && [ -d "$dest" ]; then \
            cp -a "$f/." "$dest/" || true; \
          fi; \
        else \
          cp -a "$f" "$dest" || true; \
        fi; \
      done; \
    fi && \
    rm -rf /usr/share/nginx/html-preferred /usr/share/nginx/html-fallback || true

# Copy nginx template + entrypoint (to support envsubst at container start)
# These lines assume your CI copies frontend/nginx/* into src/nginx prior to build
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /docker-entrypoint.d/entrypoint.sh
RUN chmod +x /docker-entrypoint.d/entrypoint.sh

EXPOSE 8080

# entrypoint prepares config then execs passed command (nginx) so keep CMD as before
ENTRYPOINT [ "/docker-entrypoint.d/entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]