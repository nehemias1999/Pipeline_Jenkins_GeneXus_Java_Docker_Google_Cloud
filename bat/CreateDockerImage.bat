@ECHO OFF

REM ===============================================
REM Script: CreateDockerImage.bat
REM Description: Builds a Docker image on the remote server.
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
REM Script
REM ==============================

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and builds the Docker image using the specified name and tag.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteServerDockerContentPath% ; docker build -t %DockerImageName%:%DockerImageTag% .
