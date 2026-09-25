# Spec Delta

## Purpose

Garantiza que cada artefacto desplegado sea trazable desde el commit y la KB GeneXus hasta la imagen en Artifact Registry y el deploy, con evidencia archivada.

## ADDED Requirements

### Requirement: Tags e imágenes trazables
El sistema SHALL etiquetar cada imagen como `1.<BUILD_NUMBER>-<GIT_SHA7>` con labels OCI (`revision`, `version`, `created`, `source`) y SHALL pushear a Artifact Registry con digest registrado en el log.

#### Scenario: Tag contiene SHA
- **WHEN** termina el stage de build
- **THEN** `DOCKER_IMAGE_TAG` cumple regex `^1\.[0-9]+-[0-9a-f]{7}$` y `docker inspect` muestra los 4 labels OCI

### Requirement: Provenance archivada en Jenkins
El sistema SHALL calcular `sha256sum` del WAR, archivar WAR + compose + `.env.sample` (sin secretos) con `archiveArtifacts` + `fingerprint`, y SHALL incluir BUILD_URL, GIT_COMMIT y KB version en el resumen del build.

#### Scenario: Artefactos fingerprinteados
- **WHEN** el build termina en SUCCESS
- **THEN** la página del build lista artefactos archivados con fingerprint y el `currentBuild.description` contiene commit y tag

### Requirement: Notificaciones auditables
El sistema SHALL notificar éxito/fallo con enlaces a Jenkins build, digest de imagen y ambiente destino.

#### Scenario: Notificación de fallo
- **WHEN** un stage falla
- **THEN** se emite notificación (mail/Slack según parámetro) con nombre del stage, commit y link al log
