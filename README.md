# Jenkins Pipeline – GeneXus Java Application Deployment with Docker and Google Cloud

CI/CD pipeline (Jenkins) to build, deploy and publish a GeneXus-generated Java application with Docker and Google Cloud.

## Table of Contents

- [Overview](#overview)
- [High-Level Workflow](#high-level-workflow)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Pipeline Steps](#pipeline-steps)
- [Security Considerations](#security-considerations)
- [Credentials requeridas](#credentials-requeridas)
- [Trazabilidad / Provenance](#trazabilidad--provenance)
- [Versionado multi-ambiente (TARGET_ENV + rollback)](#versionado-multi-ambiente-target_env--rollback)
- [Setup](#setup)
- [Verificación](#verificación)
- [Conclusion](#conclusion)
- [License](#license)

## Overview

This project implements a **CI/CD pipeline using Jenkins** to build, deploy, and publish a **GeneXus-generated Java application**.

The pipeline prepares the deployment artifacts, builds a Docker image on a remote Linux server, deploys the application inside a Docker container, and pushes the image to **Google Cloud Artifact Registry**.

---

## High-Level Workflow

1. Jenkins executes the pipeline defined in the `Jenkinsfile`.
2. Deployment content is prepared and copied to the remote server.
3. A Docker image is built on the remote server.
4. The application is deployed using Docker Compose.
5. Old Docker images are removed to free disk space.
6. The Docker image is pushed to Google Cloud Artifact Registry.

---

## Technologies Used

- Jenkins – CI/CD automation and orchestration
- GeneXus – Low-code platform generating the Java application
- Java / Apache Tomcat – Application runtime
- Docker – Application containerization
- Docker Compose – Container orchestration
- Bash & Batch scripts – Automation
- SSH / SCP – Secure remote server access
- Google Cloud Artifact Registry – Container image storage
- gcloud CLI – Google Cloud authentication

---

## Project Structure

Pipeline_Jenkins_GeneXus_Java_Docker_Google_Cloud/
- Jenkinsfile
- bat/
- sh/
- docker/ (Dockerfile, docker-compose.yaml, .env.template)
- openspec/ (source of truth: change pipeline-hardening-trazabilidad)
- CHANGELOG.md
- .gitattributes / .gitignore / .env.template
- README.md

---

## Pipeline Steps

### 1. Prepare Docker Deployment Content
Copies the WAR file, Docker configuration, and scripts to the remote server.

### 2. Build Docker Image
Builds the Docker image on the remote server using Docker.

### 3. Deploy Docker Image
Stops running containers and starts the new version using Docker Compose.

### 4. Cleanup Old Docker Images
Keeps only the most recent images to optimize disk usage.

### 5. Push Docker Image to Google Cloud
Authenticates and pushes the image to Artifact Registry.

---

## Security Considerations

- Credentials are managed using Jenkins Credentials (never hardcoded)
- SSH key-based authentication is used (hardened: StrictHostKeyChecking, ConnectTimeout, BatchMode, retries)
- Google Cloud access is controlled via Service Accounts
- `docker/.env` is generated at runtime from `docker/.env.template` + credentials and is never committed

---

## Credentials requeridas

Create these IDs in Jenkins (Manage Jenkins → Credentials) before running the pipeline. Values are masked as `****` in build logs.

| ID | Type | Used for |
|----|------|----------|
| `gx-server-creds` | Username + password | GeneXus Server login (`Build KB` stage) |
| `jenkins-ssh-key` | SSH username + private key | SSH/SCP to the remote Docker server (`SSH_KEY_FILE`/`SSH_USER`) |
| `gx-application-key` | Secret text | GeneXus ApplicationKey for the deploy MSBuild script |
| `gcp-sa-json` | Secret file | GCP Service Account JSON for Artifact Registry push (`GCP_SA_KEY`) |
| `db-dev-user` | Secret text | `DB_USER` in runtime `docker/.env` |
| `db-dev-pass` | Secret text | `DB_PASSWORD` in runtime `docker/.env` |
| `gam-db-user` | Secret text | `GAM_DB_USER` in runtime `docker/.env` |
| `gam-db-pass` | Secret text | `GAM_DB_PASSWORD` in runtime `docker/.env` |

Rotate any previously leaked values (old ApplicationKey, DB passwords, SA key) since they remain in git history until purged.

## Trazabilidad / Provenance

Cada artefacto desplegado es trazable desde el commit y la KB GeneXus hasta la imagen en Artifact Registry:

- **Tag trazable:** `DOCKER_IMAGE_TAG = "1.${BUILD_NUMBER}-${GIT_SHA7}"` (regex `^1\.[0-9]+-[0-9a-f]{7}$`); los tags legacy sin SHA se rechazan al inicio con mensaje actionable.
- **Labels OCI en `docker build`:** `org.opencontainers.image.revision` (SHA completo), `version` (tag), `created` (UTC), `source` (GIT_URL); verificable con `docker inspect`.
- **Provenance archivada:** `sha256sum ROOT.war | tee war.sha256` y `archiveArtifacts` + `fingerprint` de `war.sha256`, `docker/docker-compose.yaml` y `docker/.env.template`; `currentBuild.description` muestra `env + tag + sha + KB`.
- **Digest registrado:** los scripts de build/push imprimen `FULL_IMAGE:` y `DIGEST:` (RepoDigest) en el log.
- **Notificaciones auditables:** `post { success, failure }` notifica por mail (default) o Slack según `NOTIFY_CHANNEL` (`mail`|`slack`), con links a `BUILD_URL`, tag, commit y `FULL_IMAGE` + digest.

## Versionado multi-ambiente (TARGET_ENV + rollback)

- **Parámetros del job:** `TARGET_ENV` (`DEV`|`QA`|`PROD`, default `DEV`), `Force Rebuild` (boolean), `DoPush` (boolean, alias legacy `Do Docker image application to Google Cloud`), `NOTIFY_CHANNEL` (`mail`|`slack`).
- **Mapa central `ENV_CONFIG`** (cima del `Jenkinsfile`): el stage `Resolve Environment Config` resuelve por ambiente proyecto GCP, región, imagen/contenedor, `ENV_MAJOR` y credential IDs. QA/PROD nunca usan valores DEV.
- **Tag `MAJOR.BUILD-SHA`** (`ENV_MAJOR` por ambiente, default `1`): el stage de validación temprana rechaza tags legacy sin SHA (`1.42`) con mensaje actionable indicando el formato esperado; coherente con el regex `^1\.[0-9]+-[0-9a-f]{7}$`.
- **Deploy verificado:** `bat/DeployDockerImage.bat` conserva el tag previo (`.prev_tag`), hace `compose up`, espera el `healthcheck` de `docker/docker-compose.yaml` (`HEALTH_TIMEOUT` default 120s, `HEALTH_INTERVAL` default 10s) y ante fallo/timeout restaura el tag anterior, reinicia la versión previa y sale 1 (build `FAILURE`).

---

## Setup

1. Create the Jenkins credentials listed in `Credentials requeridas` (IDs must
   match exactly; QA/PROD variants use the `-qa`/`-prod` suffixed IDs from
   `ENV_CONFIG`).
2. Point a Jenkins agent labelled `SERVER_1` (Windows + GeneXus 18U9) at this
   repo; the job needs parameters `TARGET_ENV` (`DEV`|`QA`|`PROD`), `Force
   Rebuild`, `DoPush`, `NOTIFY_CHANNEL` (declared in the `Jenkinsfile`).
3. Copy nothing secret into the repo: `docker/.env` is generated at runtime
   from `docker/.env.template` + credentials. Local overrides go in an
   untracked `.env` (see `.gitignore`).
4. The remote Docker host needs the compose project under
   `/docker/<KB>/<ENV>` with `docker/docker-compose.yaml`.

---

## Verificación

Run from the repo root before opening a PR (lint tools must exit 0):

```bash
shellcheck sh/*.sh
hadolint docker/Dockerfile
yamllint docker/docker-compose.yaml
openspec validate --changes   # --strict when the CLI supports it
git status --porcelain         # must show no .env / *.war / SA JSON untracked
```

Expected: the three linters return exit 0, `openspec validate` reports 0
errors, and `git status --porcelain` shows no `.env`, WAR or `*-key.json`
files waiting to be committed (checkout-limpio).

---

## Conclusion

This pipeline provides an automated and enterprise-ready solution for deploying GeneXus Java applications using Docker and Google Cloud.

---

## License

No `LICENSE` file in this repo. All rights reserved — internal project
(see `openspec/` for the requirements source of truth).
