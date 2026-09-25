@ECHO OFF

REM ===============================================
REM Script: DeployDockerImage.bat
REM Description: Deploys the Docker image on the remote server by updating the image version tag
REM and restarting the services, then waits for the container healthcheck; on healthcheck
REM failure or timeout it restores the previous tag (automatic rollback) and exits 1 so the
REM Jenkins build is marked FAILURE.
REM Usage: DeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^> ^<DockerImageTag^> [DockerContainerName]
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM   DockerContainerName defaults to java_application_dev when omitted.
REM Env Vars: HEALTH_TIMEOUT (health wait seconds, default 120), HEALTH_INTERVAL (poll seconds, default 10).
REM Dependencies: ssh/scp (OpenSSH), docker + docker-compose on the remote host.
REM Output: STDOUT deploy/rollback progress; STDERR errors.
REM Exit codes: 0 on success (healthy); 1 when any remote deploy step fails or healthcheck
REM fails/expires (after restoring the previous tag via rollback).
REM SSH hardening: StrictHostKeyChecking=yes + ConnectTimeout=10 +
REM BatchMode=yes, 3 attempts per command, stage fails on error.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteServerDockerContentPath=%4
SET DockerImageTag=%5
SET DockerContainerName=%6
IF "%DockerContainerName%"=="" SET DockerContainerName=java_application_dev

REM Healthcheck wait budget (pipeline-versioning-multienv): overridable for slow environments.
IF "%HEALTH_TIMEOUT%"=="" SET HEALTH_TIMEOUT=120
IF "%HEALTH_INTERVAL%"=="" SET HEALTH_INTERVAL=10

REM ==============================
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

REM ==============================
REM Script
REM ==============================

REM Keeps the previous tag so a failed deploy can be rolled back automatically.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && grep '^DOCKER_IMAGE_TAG=' .env | cut -d= -f2 > .prev_tag && cat .prev_tag"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - could not read previous tag.
    exit /b 1
)

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and updates the third line of the '.env' file with the new Docker image version tag.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && sed -i '3s/.*/DOCKER_IMAGE_TAG=%DockerImageTag%/' .env"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - remote tag update failed.
    exit /b 1
)

REM Connects to the remote server via SSH, navigates to the repository directory,
REM then stops all services defined in 'docker-compose.yaml', removing orphan containers.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker-compose down --remove-orphans"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - remote compose down failed.
    exit /b 1
)

REM Removes a container if it is still running with the same name
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "docker rm -f %DockerContainerName% 2>/dev/null || true"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - remote container removal failed.
    exit /b 1
)

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and starts the services defined in 'docker-compose.yaml' in detached mode.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker-compose up --build -d"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - remote compose up failed.
    exit /b 1
)

REM Waits for the container healthcheck (timeout HEALTH_TIMEOUT); a container
REM without a health definition counts as healthy once it is running.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && t=0; while [ $t -lt %HEALTH_TIMEOUT% ]; do s=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' %DockerContainerName% 2>/dev/null || echo missing); echo \"healthcheck: container=%DockerContainerName% status=$s\"; if [ \"$s\" = \"healthy\" ] || [ \"$s\" = \"running\" ]; then echo HEALTHY; break; fi; if [ \"$s\" = \"unhealthy\" ]; then echo UNHEALTHY; exit 3; fi; sleep %HEALTH_INTERVAL%; t=$((t+%HEALTH_INTERVAL%)); done; s=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' %DockerContainerName% 2>/dev/null || echo missing); if [ \"$s\" = \"healthy\" ] || [ \"$s\" = \"running\" ]; then echo HEALTHY; else echo \"healthcheck TIMEOUT after %HEALTH_TIMEOUT%s (status=$s)\"; exit 3; fi"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - healthcheck failed or timed out, rolling back.
    GOTO :ROLLBACK
)

echo Deploy completed successfully.

GOTO :EOF

REM Restores the previous tag and restarts the prior version, leaving the
REM service in its pre-deploy state; always exits 1 so the build is FAILURE.
:ROLLBACK
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && PREV=$(cat .prev_tag) && sed -i \"3s/.*/DOCKER_IMAGE_TAG=$PREV/\" .env && docker-compose down --remove-orphans && docker rm -f %DockerContainerName% 2>/dev/null || true && docker-compose up -d && echo ROLLBACK_DONE tag=$PREV"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: DeployDockerImage - rollback itself failed, manual intervention required.
    exit /b 1
)
>&2 echo ERROR: DeployDockerImage - rolled back to previous tag, marking build FAILURE.
exit /b 1

REM Runs the ssh/scp command in %* with retries; exit 1 when attempts run out.
:SSH_RUN
SET /A __SSH_ATTEMPT=0
:SSH_RUN_LOOP
SET /A __SSH_ATTEMPT+=1
%*
IF %ERRORLEVEL%==0 EXIT /B 0
IF %__SSH_ATTEMPT% GEQ %SSH_MAX_ATTEMPTS% (
    >&2 echo ERROR: remote command failed after %SSH_MAX_ATTEMPTS% attempts.
    EXIT /B 1
)
timeout /t 5 >nul
GOTO SSH_RUN_LOOP
