# Design

## Context

Estado actual: `Jenkinsfile` monolítico con secretos literales (ApplicationKey:46, IP, paths), sin `parameters{}`/`options{}`, tag `1.BUILD_ID`; `docker/.env` con root/root versionado; SSH sin opciones seguras; Dockerfile como root sin HEALTHCHECK; compose con `version: '3.9'` obsoleta y sin healthcheck; sin lint ni rollback. Ver proposal.md para motivación.

## Goals / Non-Goals

**Goals:**
- Secretos 100% vía Jenkins credentials + `.env` efímero en workspace/remote.
- Trazabilidad commit→WAR→imagen→deploy con digest y fingerprints.
- Un Jenkinsfile multi-ambiente con rollback por healthcheck.
- Repo lint-clean y documentado.

**Non-Goals:**
- No migrar a Jenkins shared library ni a controladores cloud (se mantiene agent `SERVER_1`).
- No Workload Identity GCP en este change (se deja SA JSON vía `file` credential como paso intermedio).
- No blue/green con LB externo; rollback = re-tag + compose up previo.

## Decisions

- **Jenkins credentials bindings sobre Vault directo**: `sshUserPrivateKey` + `usernamePassword` + `string` (ApplicationKey) + `file` (SA JSON). Alternativa Vault/GCP-SM descartada por ahora por falta de infra; se deja mapa `ENV_CONFIG` para migrar sin cambiar stages.
- **`.env` generado con `writeFile` + `withCredentials`**: evita `sed '3s/.../'` frágil; plantilla `.env.template` versionada, `.env` real gitignored. Alternativa `configFileProvider` descartada por acoplamiento.
- **Tag `1.<BUILD_NUMBER>-<sha7>` + labels OCI en `docker build --label`**: trazable y compatible con el esquema `1.x` actual. Alternativa semver pura descartada porque BUILD_NUMBER es la única secuencia disponible hoy.
- **Healthcheck en Dockerfile + compose + `curl --retry` en pipeline**: triple capa barata sin dependencias extra. Alternativa `docker-compose --wait` descartada por versión antigua del CLI en server.
- **Wrappers SSH con `ssh -o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes` + reintento**: seguridad sin，另外 `BatchMode` evita prompts colgados. Se mantiene `bat/` para compat Windows-agent y `sh/` idempotentes con `set -euo pipefail`.
- **Lint local con shellcheck/hadolint/yamllint**: perfil Pipeline/CI-CD del flujo SDD; sin tests unitarios porque no hay lógica testeable en Groovy puro.

## Risks / Trade-offs

- [Rotación pendiente] Secretos ya filtrados en git siguen en historial → Mitigación: rotar DB passwords, ApplicationKey y SA key + `git filter-repo` o `BFG` en ventana acordada, documentada en tasks.
- [Known_hosts] `StrictHostKeyChecking=yes` falla si el agente no tiene el host → Mitigación: task de bootstrap documenta `ssh-keyscan` y credential `ssh-host-key`.
- [Downtime breve] `compose down/up` tiene ventana de corte → Mitigación: healthcheck + rollback rápido; blue/green queda como follow-up.
- [CRLF/LF] `.bat` vs `.sh` puede romper `sed -i` → Mitigación: `.gitattributes` + `sed -i 's/\r$//'` solo como defensa, no como fix principal.

## Migration Plan

1. Crear credentials en Jenkins (nombres en README) y rotar secretos filtrados.
2. Merge por requisito con PR (security → traceability → multienv → quality); cada PR incluye `openspec validate` + lints.
3. Post-merge: `git rm --cached docker/.env`, push `.gitignore`, purga de historial en ventana acordada.
4. Rollback: revert del PR + re-deploy del tag anterior (tasks 4.x documenta comando exacto).

## Open Questions

- Ninguna que bloquee specs o tasks; notificador final (mail vs Slack) se resuelve vía parámetro `NOTIFY_CHANNEL` con default mail.
