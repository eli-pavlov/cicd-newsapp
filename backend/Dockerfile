# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps first for better caching
COPY package*.json ./
RUN npm ci --omit=dev

# Copy the rest and (optionally) build if you transpile; if not, skip
COPY . .
# If you use TypeScript or a build step, uncomment:
# RUN npm run build

# ---- runtime stage ----
FROM node:22-alpine AS runtime
ENV NODE_ENV=production \
    PORT=8080
WORKDIR /app

# Copy only the production deps and app source
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app ./

# Create non-root user for safety
RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 8080
# Adjust if your main file differs (app.js/server.js)
CMD ["node", "app.js"]
