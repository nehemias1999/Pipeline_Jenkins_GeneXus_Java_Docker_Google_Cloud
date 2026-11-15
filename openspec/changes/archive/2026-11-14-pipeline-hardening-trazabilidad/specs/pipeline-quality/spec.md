# Spec Delta

## Purpose

Establece las buenas prácticas declarativas y de higiene del repo para que el pipeline sea reproducible, lint-clean y documentado.

## ADDED Requirements

### Requirement: Estructura declarativa robusta del Jenkinsfile
El Jenkinsfile SHALL declarar `parameters{}`, `options{}` (timestamps, timeouts por stage, buildDiscarder, disableConcurrentBuilds) y SHALL validar parámetros al inicio con `error` si son inválidos.

#### Scenario: Validación temprana
- **WHEN** se lanza con `TARGET_ENV` vacío o inválido
- **THEN** el build falla en el primer stage con mensaje actionable antes de tocar GeneXus o Docker

### Requirement: Lint y validación local reproducible
El repo SHALL pasar `shellcheck sh/*.sh`, `hadolint docker/Dockerfile` y `yamllint docker/docker-compose.yaml` con exit 0, y SHALL documentar los comandos exactos en README.

#### Scenario: Gate de lint
- **WHEN** se ejecuta la suite de lint documentada
- **THEN** los tres linters retornan 0 sin errores

### Requirement: Higiene de repo y docs vivas
El repo SHALL incluir `.gitignore` (excluye `.env`, `*.war`, SA JSON), `.gitattributes` (LF para `sh/*`, CRLF para `bat/*`), `CHANGELOG.md` actualizado por release y SHALL mantener README con setup, credentials requeridas y comandos de verificación.

#### Scenario: Checkout limpio
- **WHEN** se clona fresco y se lista con `git status --porcelain` tras generar `.env` local
- **THEN** no aparecen `.env`, WARs ni JSONs como untracked que deban commitearse
