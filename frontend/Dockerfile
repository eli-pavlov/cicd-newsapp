# syntax=docker/dockerfile:1
#################################
# Build stage
#################################
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files and install (use package-lock if present)
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --silent; elif [ -f yarn.lock ]; then npm ci --silent || true; else npm install --silent; fi

# Copy source
COPY . .

# Build args (optional)
ARG VITE_SERVER_URL=/api
ARG VITE_NEWS_INTERVAL_IN_MIN=5
ARG DEBUG_BUILD=false
ENV VITE_SERVER_URL=${VITE_SERVER_URL}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}
ENV DEBUG_BUILD=${DEBUG_BUILD}

# Run build
RUN npm run build

#################################
# Production (nginx) stage
#################################
FROM nginx:1.29.1-alpine AS runtime

# Remove default html (clean slate)
RUN rm -rf /usr/share/nginx/html/*

# Copy from build stage: check both common output locations
# 1) default Vite output: /app/dist
# 2) your observed path: /app/backend/public/app
COPY --from=build /app/dist /usr/share/nginx/html
COPY --from=build /app/backend/public/app /usr/share/nginx/html

# Optional: copy your nginx custom configuration if you have one in repo/nginx/default.conf
# If you have a custom conf that sets a different root, ensure it points to /usr/share/nginx/html
ARG NGINX_CONF_PATH=nginx/default.conf
COPY ${NGINX_CONF_PATH} /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- --no-check-certificate http://localhost/ >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
