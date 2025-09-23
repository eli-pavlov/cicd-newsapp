# ---------------------------------------------------------------------
# Multi-stage Dockerfile for the backend Node.js application.
# - Stage `build` installs production deps and prepares the app.
# - Stage `runtime` runs the app with a non-root user and runtime metadata.
# ---------------------------------------------------------------------

# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app

# Install deps first for better caching
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .



# RUN node ./services/git_info.js
# If you use TypeScript or a build step, uncomment:
# RUN npm run build

FROM node:22-alpine AS runtime

# Accept build-args (they are provided by GH Actions) and make them runtime envs
ARG BACKEND_GIT_BRANCH
ARG BACKEND_GIT_COMMIT
ENV BACKEND_GIT_BRANCH=${BACKEND_GIT_BRANCH}
ENV BACKEND_GIT_COMMIT=${BACKEND_GIT_COMMIT}

ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

# Copy only what's needed from the build stage.
# This keeps the runtime image smaller and avoids shipping build-time artifacts.
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app ./

# Create an unprivileged user and switch to it — important for container security.
RUN addgroup -S app && adduser -S app -G app
USER app

# Document the listening port. Note: EXPOSE is informational and does not publish ports.
EXPOSE 3000
# Entrypoint: run the application. Using JSON array form avoids shell processing.
CMD ["node", "./app.js"]

# ----------------- Notes & best practices (comments only) -----------------
# - Pin base image to a digest (e.g., node:22-alpine@sha256:...) in production for reproducible builds.
# - Consider adding a .dockerignore to exclude node_modules, logs, .git, etc., from the build context.
# - For reproducible installs, commit a package-lock.json and prefer `npm ci` as used here.
# - If your app needs compile/build steps (TypeScript, asset bundling), perform them in the build stage
#   and copy only the built artifacts into the runtime stage.
# - Consider adding a HEALTHCHECK to the runtime stage so orchestrators can detect unhealthy containers.
# - If secrets are required, prefer passing them via environment variables at runtime or secret stores
#   rather than baking them into the image.
# - Review image size: node:22-alpine is slim, but you can further slim by removing unnecessary files
#   or using a smaller base (e.g., distroless) if compatible with your app.
# ---------------------------------------------------------------------
