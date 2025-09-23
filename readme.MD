<img src="https://example.com/newsapp-logo.png" width="320"> 
NewsApp CI/CD Pipeline
Automated CI/CD workflows for building, testing, and deploying NewsApp backend and frontend using GitHub Actions, Docker, and Kubernetes manifests.
  ·   Documentation   ·   Report Bug   ·   Request Feature  

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
This project provides GitHub Actions workflows to automate the CI/CD pipeline for the NewsApp, a news application split into backend and frontend repositories. It handles building multi-architecture Docker images, running integration tests, pushing images to Docker Hub, and updating Kubernetes manifests in a separate repository.

Key features include:

Triggers on push, repository dispatch, or manual workflow dispatch.
Multi-arch builds for amd64 and arm64.
Tests: Backend with Postgres, Frontend with mock backend.
Environment mapping: main/master to prod/latest, others to dev.
Updates Helm values in manifests repo for dev/prod.

Source repositories:
Frontend: https://github.com/ghGill/newsAppFront
Backend: https://github.com/ghGill/newsAppBackend

This is for development and testing; enhance for production with security scans and approvals.

:rocket: TL;DR

Set up GitHub secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, MANIFESTS_REPO, GH_TOKEN.
Clone repo and push changes to trigger workflows.


Clone this repository:

bashgit clone https://github.com/ghGill/newsAppCI-CD.git

Enter the project directory:

bashcd newsAppCI-CD

Configure secrets in GitHub settings.
Push to trigger:

bashgit push
:toolbox: Getting Started
Prerequisites

GitHub repository with Actions enabled.
Docker Hub account.
Separate manifests repository for Kubernetes (e.g., with Helm charts).
Git installed locally.
Access to source repos: newsAppFront and newsAppBackend.

:gear: Installation

Clone this repository:

bashgit clone https://github.com/ghGill/newsAppCI-CD.git

Enter the project directory:

bashcd newsAppCI-CD

Review workflows:

bashvim .github/workflows/back_end.yml  # (or edit using your editor of choice)

Set up GitHub secrets:

Navigate to repo Settings > Secrets and variables > Actions.
Add secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, MANIFESTS_REPO (e.g., "ghGill/newsAppManifests"), GH_TOKEN (Personal Access Token with repo scope).


Trigger a workflow:

Push changes to backend/** or frontend/** on main/development.
Or use GitHub API for repository_dispatch:



bashcurl -X POST https://api.github.com/repos/ghGill/newsAppCI-CD/dispatches \
-H "Accept: application/vnd.github.v3+json" \
-H "Authorization: token YOUR_GH_TOKEN" \
-d '{"event_type": "backend"}'

Verify:

Check Actions tab for runs.
Images in Docker Hub under your username (e.g., newsapp-backend, newsapp-frontend).
Manifests updated in the target repo.


Cleanup (if needed):

Delete images or revert manifests manually.



:open_file_folder: Files


.github/workflows/back_end.yml: CI/CD workflow for backend: build, test, push image, update manifests.


.github/workflows/front_end.yml: CI/CD workflow for frontend: build, test, push image, update manifests.


backend/Dockerfile: Multi-stage Dockerfile for Node.js backend.


frontend/Dockerfile: Multi-stage Dockerfile for Vite frontend served by Nginx.
 frontend/nginx/default.conf.template: 
- Nginx configuration template with API proxy to backend.
 
 frontend/nginx/entrypoint.sh: 
- Entry script to substitute env vars into Nginx config and generate env.js for client-side.
 


docs/needed_envs: List of required build-time and runtime environment variables.


.dockerignore, .gitignore: Exclusion files for Docker builds and Git.


README.md: This documentation file.


:warning: License
Distributed under the MIT License. See LICENSE for more information.
:handshake: Contact
ghGill - [Your Website] - [your-email@example.com]

Project Link: https://github.com/ghGill/newsAppCI-CD.git
:gem: Acknowledgements

GitHub Actions
Docker
Kubernetes
Node.js
Vite
Nginx
Helm
Awesome README Generator