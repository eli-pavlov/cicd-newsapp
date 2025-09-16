# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps first for better caching
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
# If you use TypeScript or a build step, uncomment:
# RUN npm run build

FROM node:22-alpine AS runtime
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app ./

RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 8080
CMD ["node", "./app.js"]

