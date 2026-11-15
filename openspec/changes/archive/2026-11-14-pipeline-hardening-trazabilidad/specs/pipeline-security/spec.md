# Spec Delta

## Purpose

Define el comportamiento de seguridad del pipeline: ningún secreto persiste en git ni en logs, y todo acceso remoto e imagen cumplen hardening verificable.

## ADDED Requirements

### Requirement: Secretos solo vía Jenkins credentials
El sistema SHALL obtener ApplicationKey, SSH key, GXServer password, DB passwords y SA JSON exclusivamente desde Jenkins credentials bindings, y SHALL generar `docker/.env` en runtime sin versionarlo.

#### Scenario: Build sin secretos en repo
- **WHEN** se ejecuta `git ls-files | grep -E '^\docker/\.env$|ServiceAccount.*\.json$'` y `grep -r ApplicationKey Jenkinsfile`
- **THEN** `.env` no está trackeado y ApplicationKey no aparece literal en el repo

#### Scenario: Credenciales enmascaradas en logs
- **WHEN** corre el pipeline con credentials bindings activos
- **THEN** los valores secretos aparecen como `****` en la consola Jenkins

### Requirement: SSH y SCP endurecidos
El sistema SHALL conectar con `StrictHostKeyChecking=yes`, `ConnectTimeout`, `BatchMode=yes`, reintentos con backoff y SHALL fallar el stage si SSH/SCP falla.

#### Scenario: Fallo SSH falla el stage
- **WHEN** el host es inalcanzable o la key es inválida
- **THEN** el wrapper retorna non-zero y el stage marca FAILURE con mensaje actionable

### Requirement: Imagen Docker endurecida
La imagen SHALL correr como usuario no-root, exponer HEALTHCHECK, incluir labels OCI y SHALL no contener caches apt ni secretos.

#### Scenario: Verificación de imagen
- **WHEN** se inspecciona la imagen construida (`docker inspect`, `hadolint Dockerfile`)
- **THEN** `User` no es root, existe `Healthcheck`, existen labels `org.opencontainers.image.*` y hadolint no reporta errores DL/DS
