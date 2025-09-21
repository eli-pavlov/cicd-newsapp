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

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app ./

RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 3000
CMD ["node", "./app.js"]

