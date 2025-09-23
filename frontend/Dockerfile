# ---------------------------------------------------------------------
# Multi-stage Dockerfile for the frontend (Vite + static output) app.
# - build stage: installs deps, runs the build, and writes build metadata
# - runtime stage: nginx serves preferred build output first then falls back
# ---------------------------------------------------------------------

# --- build stage (unchanged except ensure fallback dirs exist) ---
FROM node:22-alpine AS build
WORKDIR /app

# Copy package manifests first to maximize layer caching for dependency installs.
COPY package*.json ./
# Install dependencies. Behavior:
# - Use package-lock.json -> `npm ci` (reproducible)
# - Fallback to yarn.lock if present (note: this branch calls npm as well)
# - As a last fallback, run `npm install`
# Notes / best practices:
# - Keep package-lock.json in repo and prefer `npm ci` for reproducible installs.
# - Consider using a dedicated package manager step with --prefer-offline or cache mounts:
#   e.g., in BuildKit: `RUN --mount=type=cache,target=/root/.npm ci`
# - Avoid `npm install` in CI if you expect deterministic builds.
RUN if [ -f package-lock.json ]; then npm ci --silent; elif [ -f yarn.lock ]; then npm ci --silent || true; else npm install --silent; fi

# Copy the rest of the source after deps so changes in source don't invalidate cached deps layer.
COPY . .

# Build-time args that CI sets; used to bake metadata into the image and into runtime envs if desired.
ARG VITE_SERVER_URL=/api
ARG VITE_NEWS_INTERVAL_IN_MIN=5
ARG DEBUG_BUILD=false
ARG VITE_FRONTEND_GIT_BRANCH
ARG VITE_FRONTEND_GIT_COMMIT
# Make those args available as environment variables during the build stage.
ENV VITE_SERVER_URL=${VITE_SERVER_URL}
ENV VITE_NEWS_INTERVAL_IN_MIN=${VITE_NEWS_INTERVAL_IN_MIN}
ENV DEBUG_BUILD=${DEBUG_BUILD}
ENV VITE_FRONTEND_GIT_BRANCH=${VITE_FRONTEND_GIT_BRANCH}
ENV VITE_FRONTEND_GIT_COMMIT=${VITE_FRONTEND_GIT_COMMIT}


# persist build-info into a file inside the build image
# - This file is copied into the runtime image so the container can expose build metadata.
# - Storing build metadata is a good practice for tracing which image contains which commit/branch.
RUN mkdir -p /etc/app && \
    printf 'VITE_FRONTEND_GIT_BRANCH=%s\nVITE_FRONTEND_GIT_COMMIT=%s\n' \
      "${VITE_FRONTEND_GIT_BRANCH:-}" "${VITE_FRONTEND_GIT_COMMIT:-}" \
    > /etc/app/build-info.env

# node ./src/utils/git_info.js
# If you have extra build steps (git metadata collection, linting, tests) they would run here.

# Run the static build (Vite / bundler). Ensure `npm run build` is present in package.json.
RUN npm run build

# Ensure expected output directories exist so final-stage COPY never fails.
# This reduces build failures if either path is missing in certain repo layouts.
RUN mkdir -p /app/backend/public/app /app/dist || true


# --- runtime stage ---
# Use an nginx alpine image to serve static assets.
# Best practice: pin to a digest for production to ensure immutability (e.g., nginx:1.29.1-alpine@sha256:...).
FROM nginx:1.29.1-alpine AS runtime

# copy the build-info file produced in the build stage
# Gives runtime visibility into which commit/branch was used to produce the build.
COPY --from=build /etc/app/build-info.env /etc/app/build-info.env

# (optionally) also accept runtime override ARGs
ARG VITE_FRONTEND_GIT_BRANCH
ARG VITE_FRONTEND_GIT_COMMIT
ENV VITE_FRONTEND_GIT_BRANCH=${VITE_FRONTEND_GIT_BRANCH}
ENV VITE_FRONTEND_GIT_COMMIT=${VITE_FRONTEND_GIT_COMMIT}

# Clean webroot to avoid leftover files from base image or previous steps.
RUN rm -rf /usr/share/nginx/html/*

# Copy build outputs to temporary directories (do not write directly into the real webroot)
# - preferred: `/app/backend/public/app/` (e.g., server-side rendered or preferred build)
# - fallback: `/app/dist/` (e.g., generic Vite output)
COPY --from=build /app/backend/public/app/ /usr/share/nginx/html-preferred/
COPY --from=build /app/dist/ /usr/share/nginx/html-fallback/

# Merge into real webroot without overwriting preferred files.
# Logic:
# - First copy preferred artifacts into webroot
# - Then iterate fallback artifacts and copy only when the destination doesn't exist,
#   or merge directories when both sides are directories.
# Notes & best practices:
# - This merge logic preserves a preferred build if both build outputs exist.
# - The script uses `cp -a` to retain file attributes; errors are silenced with `|| true` to
#   avoid breaking the image build on non-fatal copy errors.
# - Consider reducing complexity by having CI produce only one canonical webroot, but this
#   pattern is useful when supporting multiple build outputs or backwards compatibility.
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
# - This pattern allows the container to substitute runtime environment variables into nginx config
#   (e.g., backend host/port) at container start, which is handy for immutable container images.
# - CI is expected to copy frontend/nginx/* into the build context (src/nginx) prior to the build,
#   and those files end up in the image relative to this Dockerfile path.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/entrypoint.sh /docker-entrypoint.d/entrypoint.sh
RUN chmod +x /docker-entrypoint.d/entrypoint.sh

# Expose port that nginx will listen on. EXPOSE is documentation-only for users/orchestrators.
EXPOSE 8080

# entrypoint prepares config then execs passed command (nginx) so keep CMD as before
# Design notes:
# - Entrypoint script should be careful when performing `envsubst` to not leak secrets into logs.
# - Prefer scripts under /docker-entrypoint.d/ to be idempotent and safe to run multiple times.
ENTRYPOINT [ "/docker-entrypoint.d/entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]

# ----------------- Additional notes & recommendations (comments only) -----------------
# - Use a .dockerignore to reduce build context size (node_modules, .git, logs, local env files).
# - Consider pinning base image to a digest for reproducible builds: `node:22-alpine@sha256:...` and `nginx:1.29.1-alpine@sha256:...`.
# - Consider using BuildKit cache mounts for node_modules to speed up CI builds:
#     RUN --mount=type=cache,target=/root/.npm ci
# - If you need runtime configuration (e.g., backend host/port), prefer injecting via environment variables
#   at container run time rather than building them in, unless they are stable defaults.
# - Add a HEALTHCHECK (e.g., curl http://localhost:8080/health) to enable orchestrators to detect unhealthy containers.
# - If security is a concern, run nginx as a non-root user (the base nginx Alpine image may run as root by default).
#   Evaluate dropping privileges or using an image variant that supports non-root operation.
# - Validate the entrypoint script (`entrypoint.sh`) for correct behavior when env variables are unset and ensure
#   it exits with non-zero on misconfiguration where appropriate.
# - For strict reproducibility and supply-chain security, verify checksums of downloaded binaries (none here, but relevant if you add downloads).
# --------------------------------------------------------------------------------------------
