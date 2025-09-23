NewsApp CI/CD Pipeline
Automated build, test, and deployment for NewsApp backend and frontend using GitHub Actions, Docker, and Kubernetes.
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
This repository provides CI/CD workflows for the NewsApp, a simple news application with separate backend and frontend repositories. It automates building Docker images, running tests, pushing to Docker Hub, and updating Kubernetes manifests in a separate repo. Key features include:

Multi-arch Docker builds (amd64, arm64).
Integration tests for backend (with Postgres) and frontend (with mock backend).
Environment-specific deployments (dev/prod based on branch).
Use of GitHub Actions for automation.
Support for repository dispatch and manual triggers.

This setup is for development and testing; adapt for production with additional security and monitoring.
:rocket: TL;DR

Set up secrets in your GitHub repo (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, MANIFESTS_REPO, GH_TOKEN).
Push changes to backend/ or frontend/ paths to trigger workflows.
Or dispatch manually via workflow_dispatch.


Clone this repository:

bashgit clone https://github.com/ghGill/newsAppCI-CD.git

Enter the project directory:

bashcd newsAppCI-CD

Configure secrets in GitHub repo settings.
Trigger a build:

bashgit push
:toolbox: Getting Started
Prerequisites

GitHub account with Actions enabled.
Docker Hub account for image registry.
A separate Kubernetes manifests repository (e.g., for Helm charts).
Git installed on your machine.

:gear: Installation

Clone this repository:

bashgit clone https://github.com/ghGill/newsAppCI-CD.git

Enter the project directory:

bashcd newsAppCI-CD

Set up GitHub secrets:

Go to repo Settings > Secrets and variables > Actions.
Add: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, MANIFESTS_REPO (e.g., "ghGill/newsAppManifests"), GH_TOKEN (PAT with repo access).


Trigger workflows:

Push to main/development branches affecting backend/** or frontend/**.
Or use repository_dispatch (e.g., curl to trigger 'backend' or 'frontend').
Manual: Use GitHub UI for workflow_dispatch with inputs (source_repo, source_ref, app_name).


Verify:

Check Actions tab for build/test/push logs.
Images appear in Docker Hub.
Manifests updated in the target repo.



:open_file_folder: Files

.github/workflows/back_end.yml: Workflow for backend build, test, push, and manifests update.
.github/workflows/front_end.yml: Workflow for frontend build, test, push, and manifests update.
backend/Dockerfile: Dockerfile for backend Node.js app.
frontend/Dockerfile: Dockerfile for frontend Vite + Nginx app.
frontend/nginx/default.conf.template: Nginx config template with API proxy.
frontend/nginx/entrypoint.sh: Entry script to substitute env vars and generate env.js.
docs/needed_envs: List of required environment variables for build/runtime.
.dockerignore, .gitignore: Files to exclude from builds and Git.
LICENSE: License file (if present).
README.md: This documentation file.

:warning: License
Distributed under the MIT License. See LICENSE for more information (or add one if missing).
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