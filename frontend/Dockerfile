# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
# Optional build-time env for Vite (defaults are IP-free)
ARG VITE_SERVER_URL=/api
ARG VITE_NEWS_INTERVAL_IN_MIN=5
ENV VITE_SERVER_URL=${VITE_SERVER_URL} \
    VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}
RUN npm ci
COPY . .
RUN npm run build

# ---- serve stage ----
FROM nginx:1.27-alpine AS serve
WORKDIR /app
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx reverse proxy to backend service (runtime-configurable)
COPY frontend/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY frontend/nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:80/ || exit 1
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
