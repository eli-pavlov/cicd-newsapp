<div align="center"> <h1>NewsApp CI/CD Pipeline</h1> <p> Automated CI/CD workflows for building, testing, and deploying NewsApp backend and frontend using GitHub Actions, Docker, and Kubernetes manifests. </p> <h4> · <a href="#star2-about-the-project">About</a> · <a href="#rocket-tldr">TL;DR</a> · <a href="#toolbox-getting-started">Prerequisites</a> · <a href="#gear-installation">Installation</a> · <a href="#open_file_folder-files">Project Files</a> · <a href="#warning-license">License</a> </h4> </div>

:notebook_with_decorative_cover: Table of Contents

About the Project

TL;DR

Prerequisites

Installation

Project Files

License

Contact

Acknowledgements

:star2: About the Project

This repo provides GitHub Actions workflows to automate the CI/CD pipeline for NewsApp — a split frontend/backend application. The workflows:

Build multi-architecture Docker images (amd64, arm64).

Run lightweight integration tests (backend with Postgres, frontend with a mock backend).

Push images to Docker Hub.

Update Helm values in a separate manifests repository (dev/prod values files).

Support triggers: push (paths), repository_dispatch, and manual workflow_dispatch.

Source repositories (examples)

Frontend: https://github.com/ghGill/newsAppFront

Backend: https://github.com/ghGill/newsAppBackend

This repository is aimed at development and testing. For production use, add security scans (Snyk, Trivy), image signing, approval gates, and stricter token scopes.

:rocket: TL;DR

Add required GitHub secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, MANIFESTS_REPO, GH_TOKEN.

Push changes to frontend/** or backend/** on main / development to trigger workflows.

Or trigger manually / via repository_dispatch.

:toolbox: Getting Started
Prerequisites

GitHub repository with Actions enabled (this repo).

Docker Hub account (or adapt workflows to another registry).

A separate manifests repository (Helm charts + values/frontend/{dev,prod}.yaml, values/backend/{dev,prod}.yaml).

git installed locally.

Access to frontend/backend source repos (newsAppFront, newsAppBackend) if using the workflow inputs.

:gear: Installation
Clone repository
git clone https://github.com/ghGill/newsAppCI-CD.git
cd newsAppCI-CD

Review workflows

Open and inspect the workflows:

vim .github/workflows/back_end.yml
vim .github/workflows/front_end.yml

Set GitHub secrets

Navigate to: Settings → Secrets and variables → Actions and add:

DOCKERHUB_USERNAME — Docker Hub username

DOCKERHUB_TOKEN — Docker Hub token/password

MANIFESTS_REPO — e.g. "ghGill/newsAppManifests" (owner/repo of manifests)

GH_TOKEN — Personal Access Token with repo push rights for the manifests repo

Triggering a workflow

Push to backend/** or frontend/** on main / development.

Or trigger with the API (repository_dispatch):

# Example: trigger backend repository_dispatch
curl -X POST "https://api.github.com/repos/ghGill/newsAppCI-CD/dispatches" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token YOUR_GH_TOKEN" \
  -d '{"event_type":"backend","client_payload":{"source_repo":"ghGill/newsAppBackend","source_ref":"main","app_name":"newsapp-backend"}}'

Verify

Check the Actions tab in GitHub for workflow runs.

Verify pushed images on Docker Hub under your username (e.g., newsapp-backend, newsapp-frontend).

Check the manifests repo for updated values/*.yaml.

Cleanup

Remove images from Docker Hub manually if needed.

Revert commits in the manifests repo if the automatic update committed unwanted changes.

:open_file_folder: Files

.github/workflows/back_end.yml
CI/CD workflow for backend: build, test, push image, update manifests.

.github/workflows/front_end.yml
CI/CD workflow for frontend: build, test, push image, update manifests.

backend/Dockerfile
Multi-stage Dockerfile for Node.js backend.

backend/.dockerignore
Docker ignore for backend.

frontend/Dockerfile
Multi-stage build for Vite frontend served by Nginx.

frontend/.dockerignore
Docker ignore for frontend.

frontend/nginx/default.conf.template
Nginx configuration template that proxies /api/ to the backend (uses envsubst).

frontend/nginx/entrypoint.sh
Entrypoint that substitutes runtime vars and generates env.js for client-side code. Do not include secrets in env.js.

docs/needed_envs
Required build-time and runtime environment variables (DB, storage, Vite/Backend metadata).

.gitignore
Files to exclude from git.

README.md
This documentation file.

:warning: License

Distributed under the MIT License. See LICENSE for details.

:handshake: Contact

ghGill — [Your Website] — [your-email@example.com
]

Project Link: https://github.com/ghGill/newsAppCI-CD.git

:gem: Acknowledgements

Thanks to the open-source projects and tools used here:

GitHub Actions

Docker

Kubernetes / Helm

Node.js / Vite

Nginx

Mike Farah’s yq

Awesome README Generators

If you’d like, I can:

convert this into a fully rendered README.md file and push a PR,

add example values/*.{dev,prod}.yaml snippets to match the workflows, or

add ISSUE_TEMPLATE / PULL_REQUEST_TEMPLATE files.