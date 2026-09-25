@ECHO OFF

REM ===============================================
REM Script: CreateDockerImage.bat
REM Description: Builds a traceable Docker image on the remote server,
REM   tagging 1.BUILD_NUMBER-sha7 with OCI labels (revision, version,
REM   created, source) and printing the local image digest reference.
REM Usage: CreateDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^> ^<DockerImageName^> ^<DockerImageTag^> [^<GitSha^> ^<ImageCreated^> ^<GitUrl^>]
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM   DockerImageTag must match ^1.[0-9]+-[0-9a-f]{7}$ (traceable tag).
REM   GitSha/ImageCreated/GitUrl feed the OCI labels; default to 'unknown'/''.
REM Output: remote docker build log, then the image ID and RepoDigests lines.
REM Exit codes: 0 on success; 1 when the remote build fails after retries.
REM SSH hardening: StrictHostKeyChecking=yes + ConnectTimeout=10 +
REM BatchMode=yes, 3 attempts, stage fails on error.
REM Dependencies: ssh/scp client, remote docker daemon.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteServerDockerContentPath=%4
SET DockerImageName=%5
SET DockerImageTag=%6
SET GitSha=%7
SET ImageCreated=%8
SET GitUrl=%9
IF "%GitSha%"=="" SET GitSha=unknown
IF "%ImageCreated%"=="" SET ImageCreated=unknown
IF "%GitUrl%"=="" SET GitUrl=unknown

REM ==============================
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

REM ==============================
REM Script
REM ==============================

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and builds the Docker image with the traceable tag plus OCI labels, then
REM prints the image ID and RepoDigests so the digest lands in the build log.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker build -t %DockerImageName%:%DockerImageTag% --label org.opencontainers.image.revision=%GitSha% --label org.opencontainers.image.version=%DockerImageTag% --label org.opencontainers.image.created=%ImageCreated% --label org.opencontainers.image.source=%GitUrl% . && docker inspect --format={{.Id}} %DockerImageName%:%DockerImageTag% && docker inspect --format={{.RepoDigests}} %DockerImageName%:%DockerImageTag%"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: CreateDockerImage - remote docker build failed.
    exit /b 1
)

echo Docker image built successfully: %DockerImageName%:%DockerImageTag% rev=%GitSha%.

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
