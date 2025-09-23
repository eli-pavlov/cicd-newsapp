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
