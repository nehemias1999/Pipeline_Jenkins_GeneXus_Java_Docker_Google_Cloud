@ECHO OFF

REM ===============================================
REM Script: SetContentDockerImage.bat
REM Description: Prepares the deployment package by copying the required files
REM to the remote server directory.
REM ===============================================

REM ==============================
REM Parameters
REM ==============================

SET LocalKBEnvironmentPath=%1
SET SSHPrivateKeyPath=%2
SET SSHUser=%3
SET SSHHost=%4
SET RemoteServerDockerContentPath=%5

REM ==============================
REM Script
REM ==============================

REM Deletes the 'ROOT.war' file if it already exists.
IF exist %LocalKBEnvironmentPath%\Deploy\DOCKER\ROOT.war (
    del %LocalKBEnvironmentPath%\Deploy\DOCKER\ROOT.war
)

REM Renames the application WAR file to 'ROOT.war', which will be deployed by Tomcat.
rename %LocalKBEnvironmentPath%\Deploy\DOCKER\JAVA_APPLICATION_DEV.war ROOT.war

REM If the APK file exists, rename it and copy it to the remote server.
IF exist %LocalKBEnvironmentPath%\web\EtiquetasSD.apk ( 

    IF exist %LocalKBEnvironmentPath%\web\JAVA_APPLICATION_DEV.apk ( 
        del %LocalKBEnvironmentPath%\web\JAVA_APPLICATION_DEV.apk
    )

    REM Inserts the APK into the WAR root (no subdirectories)
    pushd "%LocalKBEnvironmentPath%\web"
    jar uf "%LocalKBEnvironmentPath%\Deploy\DOCKER\ROOT.war" JAVA_APPLICATION_DEV.apk
    popd

)

REM If the 'application' directory exists, its contents are deleted;
REM otherwise, the directory is created.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "if [ -d '%RemoteServerDockerContentPath%' ]; then echo 'REMOTE_DIR_EXISTS'; else echo 'REMOTE_DIR_NOT_EXISTS'; fi" | findstr /C:"REMOTE_DIR_EXISTS" >nul

IF %ERRORLEVEL%==0 (
    
    REM ============================
    REM REMOVE FILES ON REMOTE SERVER
    REM ============================

    ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "rm -rf %RemoteServerDockerContentPath%/*"

) ELSE (
    
    REM ============================
    REM CREATE REMOTE DIRECTORY IF IT DOES NOT EXIST
    REM ============================

    ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "mkdir -p %RemoteServerDockerContentPath%"

)

REM Creates the 'sh' directory on the remote server.
ssh -i %SSHPrivateKeyPath% %SSHUser%@%SSHHost% "mkdir -p %RemoteServerDockerContentPath%/sh"

REM Copies the 'sh' folder to the remote server directory.
scp -r -i %SSHPrivateKeyPath% sh\* %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%/sh

REM Copies the 'docker' application folder to the remote server directory.
scp -r -i %SSHPrivateKeyPath% docker\* %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%

REM Copies the .env file to the remote directory.
scp -i %SSHPrivateKeyPath% docker\.env %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%/.env

REM Copies the 'ROOT.war' file to the remote 'docker' directory.
scp -i %SSHPrivateKeyPath% %LocalKBEnvironmentPath%\Deploy\DOCKER\ROOT.war %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%
