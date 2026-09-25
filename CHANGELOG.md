<!--
  Description: Release history of the Jenkins GeneXus/Docker/GCP pipeline.
  Maintainer: pipeline-quality (openspec pipeline-hardening-trazabilidad)
  Usage: append one entry per merged PR; newest entry on top.
  Convention: Keep a Changelog (https://keepachangelog.com/en/1.0.0/).
-->

# Changelog

All notable changes to this pipeline are documented here.

## [Unreleased]

### Added

- `options{}` (timestamps, per-stage timeouts, buildDiscarder,
  disableConcurrentBuilds) + `Validate Parameters` first stage failing fast on
  empty/invalid `TARGET_ENV` (pipeline-quality).
- `.gitattributes` (LF for `sh/*`, CRLF for `bat/*`), verification commands in
  README (pipeline-quality).

### Fixed

- Removed obsolete `version: '3.9'` key from `docker/docker-compose.yaml`
  (Compose Spec v2+); healthcheck and restart policy unchanged
  (pipeline-quality).

## PR #3 — pipeline-versioning-multienv

### Added

- `parameters{TARGET_ENV, Force Rebuild, DoPush, NOTIFY_CHANNEL}` + central
  `ENV_CONFIG` map (DEV/QA/PROD resolve project, region, image, credentials).
- Traceable tag `MAJOR.BUILD-SHA` (`ENV_MAJOR` per environment) with early
  rejection of legacy tags without SHA.
- Verified deploy: healthcheck wait + automatic rollback to the previous tag
  on failure (`bat/DeployDockerImage.bat`).

## PR #2 — pipeline-traceability

### Added

- Traceable tag `1.<BUILD_NUMBER>-<sha7>` + OCI labels on `docker build`.
- `sha256sum` WAR provenance + `archiveArtifacts`/`fingerprint` +
  `currentBuild.description`.
- Success/failure notifications with links (build, digest, env).

## PR #1 — pipeline-security

### Added

- Jenkins credentials bindings (ApplicationKey, GXServer password, SSH key,
  SA JSON); no secret literals in `Jenkinsfile`.
- Runtime `docker/.env` generation from template + credentials; `.gitignore`
  coverage for `.env`/`*.war`/SA JSON.
- Hardened SSH/SCP wrappers (StrictHostKeyChecking, ConnectTimeout,
  BatchMode, retries); hardened `docker/Dockerfile` (non-root, HEALTHCHECK,
  OCI labels, no apt cache).
