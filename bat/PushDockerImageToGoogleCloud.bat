@ECHO OFF

REM ===============================================
REM Script: PushDockerImageToGoogleCloud.bat
REM Description: Pushes a Docker image to Google Cloud.
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
REM Script
REM ==============================

echo ======================================
echo Executing push on Linux server
echo Server: %SSHUser%@%SSHHost%
echo Script path: %RemoteServerDockerContentPath%/sh
echo ======================================

REM Connects to the remote server via SSH, navigates to the script directory,
REM fixes line endings, and executes the script to push the Docker image to Google Cloud.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteServerDockerContentPath%/sh ; sed -i 's/\r$//' pushDockerImageToGoogleCloud.sh ; bash pushDockerImageToGoogleCloud.sh %ProjectId% %Region% %DockerImageName% %DockerImageTag% %ServiceAccountFilePath%

IF %ERRORLEVEL% NEQ 0 (
    echo An error occurred during the build/push process.
    exit /b 1
)

echo Push completed successfully.
