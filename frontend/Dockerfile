# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Vite production build
RUN npm run build

# ---- serve stage ----
FROM nginx:1.27-alpine AS serve
WORKDIR /app

# Copy static site
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

# Add nginx template + entrypoint
COPY frontend/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY frontend/nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Basic healthcheck
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:80/ || exit 1

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
