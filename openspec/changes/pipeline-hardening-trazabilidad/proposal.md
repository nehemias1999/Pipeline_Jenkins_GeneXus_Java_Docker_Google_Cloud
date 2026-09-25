# Proposal

## Why

El pipeline actual despliega pero sin garantías de seguridad, trazabilidad ni versionado: hay secretos en git, tags no trazables y un solo ambiente DEV hardcodeado. Endurecerlo ahora evita filtraciones y permite promover a QA/PROD con auditoría.

## What Changes

- Migrar todos los secretos (ApplicationKey, SSH key, GXServer password, DB passwords, SA JSON) a Jenkins credentials bindings; generar `.env` en runtime y removerlo de git con `.gitignore`.
- Endurecer SSH/SCP (StrictHostKeyChecking, timeouts, reintentos) y scripts `bat/*.bat` + `sh/*.sh` (setlocal, quoting, `set -euo pipefail`, shellcheck limpio).
- Endurecer `docker/Dockerfile` (usuario no-root, HEALTHCHECK, labels OCI, limpieza apt) y `docker/docker-compose.yaml` (sin `version` obsoleta, healthcheck, políticas restart, validación yamllint).
- Trazabilidad total: tag `1.<BUILD_NUMBER>-<GIT_SHA corto>` + labels OCI, `sha256` del WAR, `archiveArtifacts` + `fingerprint`, notificaciones con enlaces a build/registry.
- Versionado multi-ambiente: parámetros `TARGET_ENV` (DEV/QA/PROD), `parameters{}`, `options{}` (timestamps, timeouts, buildDiscarder, disableConcurrentBuilds), despliegue con healthcheck y rollback sin downtime.
- Higiene repo: `.gitignore`, `.gitattributes` (CRLF/LF), `CHANGELOG.md`, `yamllint`/`hadolint`/`shellcheck` en validación local.

## Capabilities

### New Capabilities

- `pipeline-security`: gestión de secretos vía Jenkins credentials, SSH endurecido y hardening Docker.
- `pipeline-traceability`: tags trazables, provenance OCI, artefactos fingerprinteados y notificaciones auditables.
- `pipeline-versioning-multienv`: versionado semántico + SHA y promoción parametrizada DEV/QA/PROD.
- `pipeline-quality`: buenas prácticas declarativas del pipeline e higiene del repo (lint, timeouts, rollback, docs).

### Modified Capabilities

## Impact

- Afecta: `Jenkinsfile`, `bat/*.bat`, `sh/*.sh`, `docker/Dockerfile`, `docker/docker-compose.yaml`, `docker/.env` (sale de git), `.gitignore`, `.gitattributes`, `CHANGELOG.md`, `README.md`.
- Requiere crear credentials en Jenkins (sshUserPrivateKey, usernamePassword, secret text/file) y rotar los secretos filtrados (DB root/root, ApplicationKey, SA JSON).
- **BREAKING**: `docker/.env` deja de versionarse; el pipeline lo genera desde credentials. Builds antiguos con tag `1.BUILD_ID` dejan de ser reproducibles.
