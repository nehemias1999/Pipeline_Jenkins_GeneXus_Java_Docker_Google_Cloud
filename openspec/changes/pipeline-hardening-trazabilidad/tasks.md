# Tasks

## 1. Seguridad (pipeline-security)

- [ ] 1.1 Migrar ApplicationKey, GXServer password, SSH key y SA JSON a Jenkins credentials bindings y verificar que `grep -r ApplicationKey Jenkinsfile` no retorna literales
- [ ] 1.2 Generar `docker/.env` en runtime desde template + credentials, agregar `.gitignore` y verificar con `git ls-files | grep docker/.env` vacío y `git status --porcelain` limpio
- [ ] 1.3 Endurecer wrappers SSH/SCP (StrictHostKeyChecking, ConnectTimeout, BatchMode, reintentos) en `bat/*.bat` y verificar fallo controlado con host inválido
- [ ] 1.4 Endurecer `docker/Dockerfile` (non-root, HEALTHCHECK, labels OCI, sin cache apt) y verificar con `hadolint docker/Dockerfile` exit 0 y `docker inspect` User+Healthcheck
- [ ] 1.5 Rotar secretos filtrados (DB root/root, ApplicationKey, SA JSON) y verificar conectividad con nuevas credentials desde Jenkins

## 2. Trazabilidad (pipeline-traceability)

- [ ] 2.1 Implementar tag `1.<BUILD_NUMBER>-<sha7>` + labels OCI en build y verificar regex y `docker inspect` labels
- [ ] 2.2 Agregar `sha256sum` WAR + `archiveArtifacts`/`fingerprint` + `currentBuild.description` y verificar artefactos en página del build
- [ ] 2.3 Agregar notificaciones éxito/fallo con links (build, digest, env) y verificar notificación en build forzado a fallo

## 3. Versionado multi-ambiente (pipeline-versioning-multienv)

- [ ] 3.1 Agregar `parameters{TARGET_ENV,Force Rebuild,DoPush,NOTIFY_CHANNEL}` + mapa ENV_CONFIG y verificar que QA no usa valores DEV
- [ ] 3.2 Validar formato de tag y rechazar legacy sin SHA, verificando fallo temprano con mensaje actionable
- [ ] 3.3 Implementar espera de healthcheck + rollback automático y verificar restauración del tag previo ante fallo simulado

## 4. Calidad y buenas prácticas (pipeline-quality)

- [ ] 4.1 Agregar `options{}` (timestamps, timeouts, buildDiscarder, disableConcurrentBuilds) + validación temprana y verificar `Jenkinsfile` parsea (Jenkins Linter)
- [ ] 4.2 Fijar `docker/docker-compose.yaml` (sin version, healthcheck, restart policy) y verificar con `yamllint` exit 0
- [ ] 4.3 Agregar `.gitattributes`, `CHANGELOG.md`, `.env.template`, actualizar README con setup/credentials/comandos y verificar con `shellcheck sh/*.sh` + `yamllint` + `hadolint` todos exit 0
- [ ] 4.4 Correr `openspec validate --strict` y verificar 0 errores antes de cada PR
