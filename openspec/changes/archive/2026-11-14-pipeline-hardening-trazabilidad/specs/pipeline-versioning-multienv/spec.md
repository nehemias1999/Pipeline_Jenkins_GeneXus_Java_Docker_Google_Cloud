# Spec Delta

## Purpose

Permite versionar y promover la misma definición de pipeline entre ambientes DEV, QA y PROD sin editar código, con parámetros explícitos y despliegues seguros.

## ADDED Requirements

### Requirement: Pipeline parametrizado por ambiente
El sistema SHALL exponer `TARGET_ENV` (DEV/QA/PROD), `Force Rebuild` y `DoPush` vía bloque `parameters{}` y SHALL resolver nombres, namespaces, registry y credenciales por ambiente desde un mapa central.

#### Scenario: Selección de ambiente
- **WHEN** se lanza con `TARGET_ENV=QA`
- **THEN** el deploy usa credenciales, proyecto GCP, región e imagen correspondientes a QA y nunca valores DEV hardcodeados

### Requirement: Versionado semántico con SHA
El sistema SHALL derivar la versión como `MAJOR.BUILD-SHA` (MAJOR configurable por ambiente) y SHALL prohibir tags del formato legacy `1.BUILD_ID` sin sufijo SHA.

#### Scenario: Rechazo de tag legacy
- **WHEN** se intenta construir con tag sin sufijo SHA
- **THEN** el pipeline falla en validación temprana con mensaje que indica el formato esperado

### Requirement: Despliegue con verificación y rollback
El sistema SHALL esperar healthcheck tras `compose up`, SHALL conservar la versión anterior y SHALL hacer rollback automático si el healthcheck falla o expira el timeout.

#### Scenario: Rollback ante healthcheck fallido
- **WHEN** el nuevo contenedor no pasa healthcheck en el timeout configurado
- **THEN** el pipeline restaura el tag anterior, deja servicio en estado previo y marca el build como FAILURE
