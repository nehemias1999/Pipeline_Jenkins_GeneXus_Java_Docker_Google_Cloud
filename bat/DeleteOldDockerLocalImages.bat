@ECHO OFF

REM ===============================================
REM Script: DeleteOldDockerLocalImages.bat
REM Description: Removes old local Docker images on the remote server to free up disk space.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET SSHPrivateKeyPath=%1
SET SSHUser=%2
SET SSHHost=%3
SET RemoteServerDockerContentPath=%4

REM ==============================
REM Script
REM ==============================

REM Connects to the remote server via SSH, navigates to the script directory,
REM fixes line endings, and executes the script to remove old local Docker images.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteServerDockerContentPath%/sh ; sed -i 's/\r$//' deleteOldDockerLocalImages.sh; bash deleteOldDockerLocalImages.sh
