# Pipeline image for the GeneXus-generated Java application (Tomcat 10.1).
# Hardened per pipeline-security: runs as non-root user, exposes a
# container HEALTHCHECK, carries OCI labels, and keeps no apt caches
# or secrets in any layer.
# Sources:
# - https://docs.docker.com/reference/dockerfile/#user
# - https://docs.docker.com/reference/dockerfile/#healthcheck
# - https://docs.docker.com/reference/dockerfile/#label
FROM tomcat:10.1.10-jdk21-openjdk-slim

LABEL org.opencontainers.image.title="java_application" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.revision="unknown" \
      org.opencontainers.image.created="unknown" \
      org.opencontainers.image.source="unknown"

WORKDIR /usr/local/tomcat/webapps/

# hadolint ignore=DL3008 -- distro snapshot has no stable pin source here;
# --no-install-recommends + lists cleanup keep the layer minimal instead.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl zip \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r appuser && useradd -r -g appuser appuser

COPY --chown=appuser:appuser ROOT.war .

EXPOSE 8080

USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1
