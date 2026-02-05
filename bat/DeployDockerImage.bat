@ECHO OFF

REM ===============================================
REM Script: DeployDockerImage.bat
REM Description: Deploys the Docker image on the remote server by updating the image version tag
REM and restarting the services.
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
REM Script
REM ==============================

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and updates the third line of the '.env' file with the new Docker image version tag.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% cd %RemoteServerDockerContentPath% ; sed -i '3s/.*/DOCKER_IMAGE_TAG=%DockerImageTag%/' .env 

REM Connects to the remote server via SSH, navigates to the repository directory,
REM then stops all services defined in 'docker-compose.yaml', removing orphan containers.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker-compose down --remove-orphans"

REM Removes a container if it is still running with the same name
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "docker rm -f java_application_dev 2>/dev/null || true"

REM Connects to the remote server via SSH, navigates to the repository directory,
REM and starts the services defined in 'docker-compose.yaml' in detached mode.
REM Prints the exit status of the last executed command (usually 0 for success or 1 for error).
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "cd %RemoteServerDockerContentPath% && docker-compose up --build -d; echo \$?"
