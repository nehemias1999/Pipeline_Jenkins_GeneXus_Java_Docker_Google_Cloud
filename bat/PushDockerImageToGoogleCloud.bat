@ECHO OFF

REM ===============================================
REM Script: PushDockerImageToGoogleCloud.bat
REM Description: Pushes a traceable Docker image (tag 1.BUILD_NUMBER-sha7)
REM   to Google Cloud Artifact Registry and echoes the FULL_IMAGE reference
REM   plus its RepoDigest so the digest lands in the Jenkins build log.
REM Usage: PushDockerImageToGoogleCloud.bat ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^> ^<ProjectId^> ^<Region^> ^<DockerImageName^> ^<DockerImageTag^> ^<ServiceAccountFilePath^>
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM   ServiceAccountFilePath must be a runtime file credential (Jenkins
REM   file binding for gcp-sa-json), never a hardcoded JSON path.
REM   DockerImageTag must be the traceable tag (1.BUILD_NUMBER-sha7).
REM Output: push log, then FULL_IMAGE=... and RepoDigests lines.
REM Exit codes: 0 on success; 1 when the remote push fails after retries.
REM SSH hardening: StrictHostKeyChecking=yes + ConnectTimeout=10 +
REM BatchMode=yes, 3 attempts, stage fails on error.
REM Dependencies: ssh/scp client, remote sh/pushDockerImageToGoogleCloud.sh.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteServerDockerContentPath=%4
SET ProjectId=%5
SET Region=%6
SET DockerImageName=%7
SET DockerImageTag=%8
SET ServiceAccountFilePath=%9

REM ==============================
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

REM ==============================
REM Script
REM ==============================

echo ======================================
echo Executing push on Linux server
echo Server: %SSHUser%@%SSHHost%
echo Script path: %RemoteServerDockerContentPath%/sh
echo ======================================

REM Connects to the remote server via SSH, navigates to the script directory,
REM fixes line endings, and executes the script to push the Docker image to Google Cloud.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath%/sh && sed -i 's/\r$//' pushDockerImageToGoogleCloud.sh && bash pushDockerImageToGoogleCloud.sh %ProjectId% %Region% %DockerImageName% %DockerImageTag% %ServiceAccountFilePath%"

IF %ERRORLEVEL% NEQ 0 (
    >&2 echo An error occurred during the build/push process.
    exit /b 1
)

REM Propagates the traceable tag into the Artifact Registry reference and
REM echoes the digest so notifications can link image + digest (best effort:
REM a missing digest never fails the push itself).
SET FullImage=%Region%-docker.pkg.dev/%ProjectId%/docker/%DockerImageName%:%DockerImageTag%
echo FULL_IMAGE=%FullImage%
ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "docker inspect --format={{.RepoDigests}} %FullImage%"
echo Push completed successfully: %FullImage%.

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
