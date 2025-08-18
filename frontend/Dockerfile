# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

# Pass Vite args from build args
ARG VITE_SERVER_URL
ARG VITE_NEWS_INTERVAL_IN_MIN
ENV VITE_SERVER_URL=$VITE_SERVER_URL
ENV VITE_NEWS_INTERVAL_IN_MIN=$VITE_NEWS_INTERVAL_IN_MIN

COPY . .
RUN npm run build

# ---- serve stage ----
FROM nginx:1.27-alpine
WORKDIR /app

# Remove default html
RUN rm -rf /usr/share/nginx/html/*

# ✅ Copy the actual build output (matches your Vite log)
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx reverse proxy config
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
