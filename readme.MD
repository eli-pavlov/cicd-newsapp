<div align='center'>
<h1>NewsApp CI/CD Pipeline</h1>

<p>Automated CI/CD workflows for building, testing, and deploying NewsApp backend and frontend using GitHub Actions, Docker, and Kubernetes manifests.</p>

<h4>
  <span> · </span>
  <a href="#star2-about-the-project">About</a>
  <span> · </span>
  <a href="#rocket-tldr">TL;DR</a>
  <span> · </span>
  <a href="#toolbox-getting-started">Prerequisites</a>
  <span> · </span>
  <a href="#gear-installation">Installation</a>
  <span> · </span>
  <a href="#open_file_folder-files">Project Files</a>
  <span> · </span>
  <a href="#warning-license">License</a>
</h4>
</div>

:notebook_with_decorative_cover: **Table of Contents**

- [:star2: About the Project](#star2-about-the-project)
- [:rocket: TL;DR](#rocket-tldr)
- [:toolbox: Getting Started — Prerequisites](#toolbox-getting-started--prerequisites)
- [:gear: Installation](#gear-installation)
- [:handshake: Contact](#handshake-contact)
- [:gem: Acknowledgements and thanks to:](#gem-acknowledgements-and-thanks-to)

---

<a id="star2-about-the-project"></a>
## :star2: About the Project

This repository contains opinionated GitHub Actions workflows that implement a CI/CD pipeline for **NewsApp** — a split frontend / backend application.

Workflows included:

- Build multi-architecture Docker images (amd64, arm64) for frontend and backend.
- Run lightweight integration/unit tests (example: backend + postgres, frontend with a mock backend).
- Push images to a container registry (Docker Hub by default).
- Update a separate manifests repository (Helm values files or plain YAML) with new image tags for `dev`/`prod`.
- Support triggers: `push` (path filters), `repository_dispatch`, and manual `workflow_dispatch`.

> This repository is intended for **development / CI** usage. For production you should add stricter security controls, image signing, vulnerability scans (Snyk/Trivy), and approval gates.

---

<a id="rocket-tldr"></a>
## :rocket: TL;DR

1. Add required GitHub secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `MANIFESTS_REPO`, `GH_TOKEN`.  
2. Push to `frontend/**` or `backend/**` on `main` / `development` to trigger pipelines.  
3. Or trigger via `repository_dispatch` for remote automation.  
4. Check the **Actions** tab for logs and the manifests repo for updated values.

---

<a id="toolbox-getting-started"></a>
## :toolbox: Getting Started — Prerequisites

- GitHub repository with Actions enabled (this repo).
- Docker Hub account (or adjust registry steps to your preferred registry).
- A separate manifests repository (Helm charts or YAML manifests) with paths like:
  - `values/frontend/dev.yaml`
  - `values/frontend/prod.yaml`
  - `values/backend/dev.yaml`
  - `values/backend/prod.yaml`
- `git` installed locally.
- (Optional) Personal Access Token (`GH_TOKEN`) with permission to push commits to `MANIFESTS_REPO`.

---

<a id="gear-installation"></a>
## :gear: Installation

1. **Clone this repo**
```bash
git clone https://github.com/eli-pavlov/cicd-newsapp.git
cd cicd-newsapp
Review the workflows

bash
Copy code
ls .github/workflows
# open the workflow files
vim .github/workflows/back_end.yml
vim .github/workflows/front_end.yml
```

Set GitHub Secrets
Go to: Settings → Secrets and variables → Actions and add:

DOCKERHUB_USERNAME — Docker Hub username

DOCKERHUB_TOKEN — Docker Hub token/password (or use PAT if using GHCR)

MANIFESTS_REPO — e.g. eli-pavlov/newsapp-manifests

GH_TOKEN — Personal Access Token with repo write rights for MANIFESTS_REPO

(Optional) Adjust workflow inputs
If you use private source repos for frontend/backend, update the workflow inputs or the source_repo values used by the build job.

<a id="wrench-usage--triggering-workflows"></a>

:wrench: Usage / Triggering Workflows
Push trigger
Changes under frontend/** or backend/** on main or development will trigger the corresponding workflow.

Manual trigger (workflow_dispatch)
Open the Actions tab, pick a workflow, and click Run workflow. Provide any required inputs (branch, tag, target manifest path).

repository_dispatch (remote automation / CI integration)
Example: trigger the backend pipeline remotely:

```bash
Copy code
curl -X POST "https://api.github.com/repos/<owner>/<repo>/dispatches" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token YOUR_GH_TOKEN" \
  -d '{
    "event_type": "backend",
    "client_payload": {
      "source_repo": "ghGill/newsAppBackend",
      "source_ref": "main",
      "app_name": "newsapp-backend"
    }
  }'
```

Replace YOUR_GH_TOKEN and repo names with appropriate values.

<a id="open_file_folder-files"></a>

:open_file_folder: Files
This repo contains the following important files and folders:

.github/workflows/back_end.yml — CI/CD workflow for backend: build, test, push image, update manifests.

.github/workflows/front_end.yml — CI/CD workflow for frontend: build, test, push image, update manifests.

backend/Dockerfile — Multi-stage Dockerfile for Node.js backend.

backend/.dockerignore — Docker ignore for backend.

frontend/Dockerfile — Multi-stage build for Vite frontend served by Nginx.

frontend/.dockerignore — Docker ignore for frontend.

frontend/nginx/default.conf.template — Nginx configuration template that proxies /api/ to backend (uses envsubst).

frontend/nginx/entrypoint.sh — Entrypoint script that substitutes runtime vars and generates env.js for client-side usage. Do not insert secrets into env.js.

docs/needed_envs — list of required build-time and runtime env variables (DB, storage, Vite metadata, etc.).

.gitignore — files to exclude from git.

README.md — this file.

$~$

<details> <summary>File snippets / quick notes</summary>
frontend/nginx/default.conf.template:

uses ${BACKEND_SERVICE_HOST} and ${BACKEND_SERVICE_PORT} for runtime substitution.

entrypoint performs envsubst to create final default.conf.

Entrypoint considerations:

env.js must never contain secrets; use runtime-only server-side injections or secure endpoints.

Ensure entrypoint.sh copies frontend/Dockerfile assets into build context when used by combined repository workflows.

$~$

</details>
<a id="eyeglasses-how-to-verify-outputs"></a>

:eyeglasses: How to verify outputs
Actions logs: open the Actions tab → select a run → view job logs (build, test, push steps).

Docker images: check your Docker Hub namespace (or GHCR) for newly pushed tags (e.g., dev-<sha> / latest-<sha>).

Manifests repo: inspect MANIFESTS_REPO (commits/PRs) for updated values/* files and verify the image tags were updated as expected.

Local test runs: you can simulate the build locally with docker buildx (if multi-arch is enabled) or run unit tests with npm ci && npm test in each project.

Quick commands
List recent images on Docker Hub (local Docker CLI won't list remote images — use the web UI or registry API).

To check a committed values file locally after workflow updates:

bash
Copy code
git clone https://github.com/<owner>/<manifests-repo>.git
cd <manifests-repo>
git log -n 5 -- values/frontend/dev.yaml
sed -n '1,120p' values/frontend/dev.yaml

$~$

<a id="warning-license"></a>

:warning: License
Distributed under the MIT License. See LICENSE for details.

<a id="handshake-contact"></a>

$~$

## :handshake: Contact

Eli Pavlov - www.weblightenment.com - admin@weblightenment.com

Project Link: https://github.com/eli-pavlov/cicd-newsapp.git

$~$

## :gem: Acknowledgements and thanks to:

- [Awesome Github Readme File Generator](https://www.genreadme.cloud/)