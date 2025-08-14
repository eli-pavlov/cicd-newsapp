# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# deps first for better caching
COPY package*.json ./
RUN npm ci

# Provide Vite envs at build time (from --build-arg)
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN
ENV VITE_SERVER_URL=${VITE_SERVER_URL}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}

# build
COPY . .
RUN npm run build

# ---- serve stage ----
FROM nginx:1.27-alpine AS serve
# Serve our static build
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

# SPA fallback + simple health endpoint
RUN printf 'server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  include /etc/nginx/mime.types;\n\
  location /healthz { return 200 "ok"; add_header Content-Type text/plain; }\n\
  location / { try_files $uri $uri/ /index.html; }\n\
}\n' > /etc/nginx/conf.d/default.conf

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/healthz || exit 1
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
