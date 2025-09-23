<div align="center">
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/githubactions/githubactions-original.svg" alt="GitHub Actions Logo" width="100" height="100"/>
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/docker/docker-original.svg" alt="Docker Logo" width="100" height="100"/>
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/kubernetes/kubernetes-plain.svg" alt="Kubernetes Logo" width="100" height="100"/>
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/helm/helm-original.svg" alt="Helm Logo" width="100" height="100"/>

  <h1>NewsApp CI/CD Pipeline</h1>
</div>

This repository contains the CI/CD pipelines for the **NewsApp** project, built with **GitHub Actions**. It automates the process of building, testing, and publishing Docker images for the frontend and backend services, and integrates with a GitOps workflow by updating Kubernetes manifests.

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/YOUR_USERNAME/YOUR_REPONAME/front_end.yml?branch=main&label=Frontend%20Pipeline&style=for-the-badge" alt="Frontend Pipeline Status"/>
  <img src="https://img.shields.io/github/actions/workflow/status/YOUR_USERNAME/YOUR_REPONAME/back_end.yml?branch=main&label=Backend%20Pipeline&style=for-the-badge" alt="Backend Pipeline Status"/>
</p>

---

## 🚀 Features

-   **Automated Builds**: Independent pipelines for frontend and backend, triggered on push, manual dispatch, or remote API calls.
-   **Multi-Architecture Images**: Builds and pushes `linux/amd64` and `linux/arm64` Docker images to Docker Hub.
-   **Automated Testing**: Each pipeline runs integration tests in an isolated Docker environment before pushing the image.
-   **Dynamic Tagging**: Docker images are automatically tagged based on the source Git branch and commit SHA (e.g., `latest-a1b2c3d` for `main`, `dev-e4f5g6h` for other branches).
-   **GitOps Integration**: Automatically updates image tags in a separate Kubernetes manifests repository, keeping your deployments in sync with your code.
-   **Flexible Triggers**: Workflows can be started by pushing code, running them manually from the GitHub UI, or via a `repository_dispatch` event for easy integration with other tools.

---

##  Pipelines Overview

Both the frontend and backend pipelines follow a similar, multi-job workflow to ensure reliability and clear separation of concerns.

**Pipeline Flow:**
`Trigger` ➡️ `Build & Test Job` ➡️ `Push & Update Manifests Job`

1.  **Trigger**: A workflow run is initiated by a `push` to a specific path, a manual `workflow_dispatch`, or a `repository_dispatch` event.
2.  **Build Job**:
    -   Checks out the application's source code from its repository.
    -   Builds a single-architecture (`linux/amd64`) Docker image locally.
    -   Saves the build context (like the generated image tag) as an artifact.
3.  **Test Job**:
    -   Downloads the build context artifact.
    -   Pulls the just-built image (or uses the local build if on the same runner).
    -   Spins up the application and its dependencies (e.g., a test database) in Docker.
    -   Runs a simple health check or integration test against the running container.
4.  **Push & Update Manifests Job**:
    -   Downloads the build context artifact.
    -   Performs a final, multi-architecture build and pushes the image to Docker Hub.
    -   Checks out the Kubernetes manifests repository.
    -   Uses `yq` to update the appropriate Helm `values.yaml` file (`dev.yaml` or `prod.yaml`) with the new image tag.
    -   Commits and pushes the change back to the manifests repository.

---

## ⚙️ Prerequisites and Setup

To use these pipelines, you need to configure the following secrets in your GitHub repository.

➡️ Navigate to `Settings` > `Secrets and variables` > `Actions` and add the following **repository secrets**.

| Secret                 | Description                                                                                             | Example                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `DOCKERHUB_USERNAME`   | Your Docker Hub username.                                                                               | `my-docker-user`                      |
| `DOCKERHUB_TOKEN`      | A Docker Hub Access Token with read/write permissions.                                                  | `dckr_pat_...`                        |
| `MANIFESTS_REPO`       | The slug of your Kubernetes manifests repository (owner/repo).                                          | `ghGill/newsapp-manifests`            |
| `GH_TOKEN`             | A GitHub Personal Access Token (PAT) with `repo` scope to push updates to the manifests repository.     | `ghp_...`                             |

### **Manifests Repository Structure**

The pipelines expect your manifests repository to have a structure similar to this, containing Helm values files that will be updated automatically:

```bash

newsapp-manifests/
└── values/
├── backend/
│   ├── dev.yaml
│   └── prod.yaml
└── frontend/
├── dev.yaml
└── prod.yam
```

---

## ▶️ How to Use

You can trigger the workflows in three ways:

1.  **On Push (Most Common)**
    -   Pushing changes to the `frontend/**` directory on the `main` or `development` branch will automatically trigger the frontend pipeline.
    -   Pushing changes to the `backend/**` directory will trigger the backend pipeline.

2.  **Manual Trigger (`workflow_dispatch`)**
    -   Go to the **Actions** tab in your GitHub repository.
    -   Select either the `Build, Test, & Push Frontend Image` or `... Backend Image` workflow.
    -   Click the **`Run workflow`** dropdown.
    -   You can specify the source repository, branch/ref, and application name to build from.

3.  **Remote Trigger (`repository_dispatch`)**
    -   You can trigger a workflow from an external script or service by sending a POST request to the GitHub API. This is useful for integrating with other systems.

    ```bash
    # Example: Trigger the backend pipeline remotely
    curl -X POST "[https://api.github.com/repos/YOUR_USER/YOUR_REPO/dispatches](https://api.github.com/repos/YOUR_USER/YOUR_REPO/dispatches)" \
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

---

## 📂 Repository Structure\

```bash
cicd-newsapp/
├── .github/workflows/
│   ├── back_end.yml      # CI/CD pipeline for the backend service.
│   └── front_end.yml     # CI/CD pipeline for the frontend service.
├── backend/
│   ├── Dockerfile        # Multi-stage Dockerfile for the Node.js backend.
│   └── .dockerignore     # Specifies files to exclude from the build context.
├── frontend/
│   ├── Dockerfile        # Multi-stage Dockerfile for the Vite frontend (served by NGINX).
│   ├── .dockerignore
│   └── nginx/
│       ├── default.conf.template # NGINX config template for proxying API requests.
│       └── entrypoint.sh         # Script to substitute env vars at container start.
└── information/
└── needed_envs  
     # A reference list of application environment variables.
```

---

## 🧩 Application Configuration

The infrastructure is designed to run the `newsApp` application, which is deployed via Argo CD from the following source repositories:
-   **Frontend**: `https://github.com/ghGill/newsAppFront`
-   **Backend**: `https://github.com/ghGill/newsAppbackend`

The following environment variables are required by the application itself. These are **not** CI/CD variables; they should be managed as Kubernetes secrets (ideally using a tool like Sealed Secrets) and applied to your deployments.

### **Frontend Environment Variables**

#### Build-Time (Vite)

| Variable                      | Description                               | Example                                  |
| ----------------------------- | ----------------------------------------- | ---------------------------------------- |
| `VITE_SERVER_URL`             | The base path for API requests.           | `/api`                                   |
| `VITE_NEWS_INTERVAL_IN_MIN`   | The interval in minutes to fetch news.    | `5`                                      |
| `VITE_FRONTEND_GIT_BRANCH`    | Git branch of the frontend build.         | `main`                                   |
| `VITE_FRONTEND_GIT_COMMIT`    | Git commit SHA of the frontend build.     | `a1b2c3d`                                |

#### Runtime (NGINX)

| Variable                   | Description                                             | Example                                  |
| -------------------------- | ------------------------------------------------------- | ---------------------------------------- |
| `BACKEND_SERVICE_HOST`     | The internal Kubernetes service hostname for the backend. | `backend.default.svc.cluster.local`      |
| `BACKEND_SERVICE_PORT`     | The port of the backend service.                        | `8080`                                   |

### **Backend Environment Variables**

#### Database Configuration

| Variable         | Description                                                        | Example      |
| ---------------- | ------------------------------------------------------------------ | ------------ |
| `DB_ENGINE_TYPE` | The database engine type (`POSTGRES`, `MONGO`, etc.).              | `POSTGRES`   |
| `DB_PROTOCOL`    | The database connection protocol.                                  | `postgresql` |
| `DB_USER`        | The database username.                                             | `news_user`  |
| `DB_PASSWORD`    | The database password. **(Should be a secret)** | `s3cr3t_p4ss`|
| `DB_HOST`        | The internal Kubernetes service hostname for the database.         | `postgresql-prod-client.default.svc.cluster.local` |
| `DB_PORT`        | The port for the database service.                                 | `5432`       |
| `DB_NAME`        | The name of the database.                                          | `newsdb_prod`|

#### Storage Configuration

| Variable                | Description                                                                                                   | Example                      |
| ----------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `STORAGE_TYPE`          | The storage backend type (`AWS_S3` or `DISK`).                                                                | `AWS_S3`                     |
| `AWS_ACCESS_KEY_ID`     | AWS Access Key ID. **(Required if `STORAGE_TYPE` is `AWS_S3`)** | `AKIA...`                    |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key. **(Required if `STORAGE_TYPE` is `AWS_S3`; should be a secret)** | `wJal...`                    |
| `AWS_REGION`            | The AWS region for the S3 bucket. **(Required if `STORAGE_TYPE` is `AWS_S3`)** | `us-east-1`                  |
| `AWS_BUCKET`            | The name of the S3 bucket. **(Required if `STORAGE_TYPE` is `AWS_S3`)** | `my-app-data-bucket`         |
| `DISK_ROOT_PATH`        | The root path on the disk for local storage. **(Required if `STORAGE_TYPE` is `DISK`)** | `/data/movies`               |

#### Build Information

| Variable             | Description                              | Example   |
| -------------------- | ---------------------------------------- | --------- |
| `BACKEND_GIT_BRANCH` | Git branch of the backend build.         | `main`    |
| `BACKEND_GIT_COMMIT` | Git commit SHA of the backend build.     | `e4f5g6h` |