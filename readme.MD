newsApp — CI/CD & Docker build repo
<div align="center"> <img src="https://raw.githubusercontent.com/eli-pavlov/vagrant-kubernetes-EZ/master/docs/logo.webp" width="280" alt="logo" /> <h1>newsApp — CI/CD / Build workflows</h1> <p>Repository that holds CI workflows, Dockerfiles and helper docs for the newsApp frontend & backend builds and automated manifest updates (push → test → push image → update manifests).</p> <h4> · <a href="#star2-about-the-project">About</a> · <a href="#rocket-tldr">TL;DR</a> · <a href="#toolbox-prerequisites">Prerequisites</a> · <a href="#gear-usage">Usage</a> · <a href="#open_file_folder-files">Files</a> · <a href="#license">License</a> </h4> </div>
:star2: About the project

This repo contains the CI workflows, Dockerfiles and helper docs for building, testing and publishing the newsApp frontend and backend images and for updating the Kubernetes manifests repository automatically.

Main features:

GitHub Actions workflows for:

building multi-arch images,

running quick integration tests (containers + minimal DB/mock),

pushing images to Docker Hub,

updating manifests repo (values files) and pushing changes back.

Docker multi-stage Dockerfiles for frontend (Vite + Nginx) and backend (Node).

docs/needed_envs with runtime/build environment variables the services expect.

Opinionated defaults and best-practices embedded in workflows (artifacts to pass metadata, yq/helm linting, non-root runtime user in backend image).

:rocket: TL;DR

Build & test run automatically on push to main / development when frontend/backend paths are changed.

Workflows also support repository_dispatch (types frontend / backend) and manual workflow_dispatch with inputs.

Workflows expect a separate manifests repository (secret MANIFESTS_REPO) with values/frontend/{dev,prod}.yaml and values/backend/{dev,prod}.yaml and relevant Helm charts.

Required GitHub secrets (see Prerequisites) must be set in the Actions secrets for the workflows to push images and update manifests.

:toolbox: Prerequisites

Local / CI expectations:

Docker (for local builds/tests)

(Optional) gh or curl to trigger repository dispatches / workflow_dispatch

yq and helm are installed in CI steps (workflows install them automatically)

Docker Hub account (or another registry supported by the workflow); the workflows use Docker Hub by default.

Required GitHub secrets (workflow names refer to these exact variables):

DOCKERHUB_USERNAME — Docker Hub username

DOCKERHUB_TOKEN — Docker Hub token/password

MANIFESTS_REPO — owner/repo of the manifests repository (used when workflows push updated values)

GH_TOKEN — a GitHub token with repo:contents / push rights for the manifests repo

CI environment variables set in workflows (defaults you can override in Actions):

MANIFESTS_BRANCH — branch in manifests repo (default: main)

YQ_VERSION — which yq release to install (default in workflows: v4.44.3)

:gear: Usage
Triggering CI

Push changes to frontend/** or backend/** on main / development — corresponding workflow runs automatically.

Manual run via GitHub UI: open workflow and Run workflow, fill inputs.

Repository dispatch (example curl request to trigger backend type):

# Example (use a PAT in $GH_TOKEN)
curl -X POST -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/<owner>/<repo>/dispatches \
  -d '{"event_type":"repository_dispatch","client_payload":{"source_repo":"ghGill/newsAppBackend","source_ref":"main","app_name":"newsapp-backend"}}'


(Replace <owner>/<repo> with this repo, and GH_TOKEN with an appropriate token.)

What the workflows do (short)

Backend workflow (.github/workflows/back_end.yml)

Checkout this CI repo.

Resolve build context + checkout backend source (to src/).

Compute tags (latest-<sha> for main, dev-<sha> otherwise).

Build multi-arch image and push to Docker Hub.

Upload a small job-context artifact (image metadata).

Run integration tests (start postgres container, pull built image, run container, call /db/available).

Checkout manifests repo and update values/backend/{dev|prod}.yaml with .image.repository and .image.tag, lint with helm lint, commit & push.

Frontend workflow (.github/workflows/front_end.yml)

Very similar flow for the frontend:

build (local load for tests), upload job-context-frontend artifact,

run a simple mock backend + frontend container to validate response,

then multi-arch push and update values/frontend/{dev|prod}.yaml (and set runtime .env.plain.BACKEND_SERVICE_HOST/PORT based on backend values), lint & push manifests.

Important artifact names:

job-context (backend)

job-context-frontend (frontend)

Local quick test / building

You can run a quick local build & smoke test for each component.

Backend (local build & run):

# from repo root
docker build -f backend/Dockerfile -t newsapp-backend:local-backend ./backend
docker run --rm -p 3000:3000 \
  -e DB_ENGINE_TYPE=POSTGRES \
  -e DB_PROTOCOL=postgres \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=news_app \
  newsapp-backend:local-backend

# then curl the health endpoint:
curl http://localhost:3000/db/available


Frontend (local build & run):

# build the static frontend image
docker build -f frontend/Dockerfile -t newsapp-frontend:local-frontend ./frontend
# run with a mock backend using Docker network or map BACKEND_SERVICE_HOST to a reachable host
docker run --rm -p 8080:8080 \
  -e BACKEND_SERVICE_HOST=host.docker.internal \
  -e BACKEND_SERVICE_PORT=3000 \
  newsapp-frontend:local-frontend

# open http://localhost:8080


Notes:

host.docker.internal works on many platforms to reach host services from a container; adjust as needed.

The frontend image exposes env.js (generated by entrypoint) with runtime metadata — do not expose secrets there.

Configuration: environment variables

See docs/needed_envs for the canonical list. Key runtime variables include:

Backend DB:

DB_ENGINE_TYPE — POSTGRES | MONGO | MYSQL etc.

DB_PROTOCOL, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME

Storage:

STORAGE_TYPE — AWS_S3 or DISK

AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_BUCKET (when AWS_S3)

DISK_ROOT_PATH (when DISK)

Frontend build/runtime:

build args: VITE_SERVER_URL, VITE_NEWS_INTERVAL_IN_MIN

runtime env (via entrypoint) BACKEND_SERVICE_HOST, BACKEND_SERVICE_PORT

build metadata: VITE_FRONTEND_GIT_BRANCH, VITE_FRONTEND_GIT_COMMIT

Backend build metadata:

BACKEND_GIT_BRANCH, BACKEND_GIT_COMMIT

Security reminder: the entrypoint writes env.js (served publicly). Never put secrets there.

:open_file_folder: Files

.github/workflows/back_end.yml — backend build/test/push and manifests updater

.github/workflows/front_end.yml — frontend build/test/push and manifests updater

backend/Dockerfile, backend/.dockerignore — backend image build

frontend/Dockerfile, frontend/.dockerignore — frontend build (Vite → Nginx)

frontend/nginx/default.conf.template — nginx proxy template (uses envsubst)

frontend/nginx/entrypoint.sh — runtime entrypoint that builds env.js

docs/needed_envs — list of envs and examples

.gitignore — repo ignores

README.md — (this file)

Development notes & best practices

Pin base images to a digest in production (e.g., node:22-alpine@sha256:... and nginx@sha256:...) for reproducible builds.

Consider adding a HEALTHCHECK to the images so Kubernetes / orchestrator can probe liveness/readiness.

The workflows demonstrate safe patterns:

artifact passing (job-context*) instead of re-computing metadata,

helm lint and helm template before committing changes,

early secret validation step to fail fast.

If your manifests repo uses a different layout, adjust the file paths in the workflows:

Backend values: values/backend/{dev,prod}.yaml

Frontend values: values/frontend/{dev,prod}.yaml

The frontend entrypoint uses envsubst to substitute only the allowed variables — keep that list tight to avoid accidental substitutions.

Contributing

Contributions welcome — open an issue or a PR. If you update any of the workflows, please:

Prefer pinning action versions to a SHA or specific release.

Run the workflows locally (where possible) or in a disposable branch before merging to main.

Update docs/needed_envs if new runtime variables are required.

:warning: Troubleshooting tips

Workflow fails with missing secret — check the repository settings → Secrets and create the missing secret.

helm lint fails when workflow updates manifests — validate the values file syntax locally with yq -r and helm lint.

Image push fails — verify DOCKERHUB_TOKEN and DOCKERHUB_USERNAME are valid and have repository push rights; check Docker Hub rate limits.

Local container cannot reach DB — ensure DB is reachable from the container (host.docker.internal or user-defined bridge network).

License

Distributed under the Apache 2.0 License. See LICENSE.txt if present.

:handshake: Contact

Eli Pavlov — www.weblightenment.com
 — admin@weblightenment.com

Repo: https://github.com/<your-org-or-user>/<repo> (replace with actual remote)

:gem: Acknowledgements

Thanks to the many open-source projects and examples that inspired this layout: Docker, Helm, Mike Farah’s yq, GitHub Actions community actions, nginx, Node.js images and many others.

If you want, I can:

generate example values/*.{dev,prod}.yaml snippets matching the workflows,

add a .github/ISSUE_TEMPLATE and PULL_REQUEST_TEMPLATE,

or produce a pared-down Makefile for local dev tasks (build/test/push emulation).