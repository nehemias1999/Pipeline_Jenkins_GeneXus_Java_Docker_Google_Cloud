@ECHO OFF

REM ===============================================
REM Script: CreateDockerImage.bat
REM Description: Builds a Docker image on the remote server.
REM Usage: CreateDockerImage.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^> ^<DockerImageName^> ^<DockerImageTag^>
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM Exit codes: 0 on success; 1 when the remote build fails after retries.
REM SSH hardening: StrictHostKeyChecking=yes + ConnectTimeout=10 +
REM BatchMode=yes, 3 attempts, stage fails on error.
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

REM ==============================
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

REM ==============================
REM Script
REM ==============================

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and builds the Docker image using the specified name and tag.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker build -t %DockerImageName%:%DockerImageTag% ."
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: CreateDockerImage - remote docker build failed.
    exit /b 1
)

echo Docker image built successfully.

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
