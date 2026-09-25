@ECHO OFF

REM ===============================================
REM Script: DeployDockerImage.bat
REM Description: Deploys the Docker image on the remote server by updating the image version tag
REM and restarting the services.
REM Usage: DeployDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^> ^<DockerImageTag^>
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM Exit codes: 0 on success; 1 when any remote deploy step fails after retries.
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

REM ==============================
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

REM ==============================
REM Script
REM ==============================

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
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "docker rm -f java_application_dev 2>/dev/null || true"
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

echo Deploy completed successfully.

GOTO :EOF

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
