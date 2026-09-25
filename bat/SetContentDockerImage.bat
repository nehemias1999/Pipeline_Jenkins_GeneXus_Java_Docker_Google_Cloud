@ECHO OFF

REM ===============================================
REM Script: SetContentDockerImage.bat
REM Description: Prepares the deployment package by copying the required files
REM to the remote server directory.
REM Usage: SetContentDockerImage.bat ^<LocalKBEnvironmentPath^> ^<SSHPrivateKeyPath^> ^<SSHUser^> ^<SSHHost^> ^<RemoteServerDockerContentPath^>
REM   SSHPrivateKeyPath must be a runtime credential file (Jenkins
REM   sshUserPrivateKey binding), never a hardcoded path.
REM Exit codes: 0 on success; 1 when any remote copy step fails after retries.
REM SSH hardening: StrictHostKeyChecking=yes + ConnectTimeout=10 +
REM BatchMode=yes, 3 attempts per command, stage fails on error.
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
REM SSH hardening (pipeline-security)
REM ==============================

SET SSH_OPTS=-o StrictHostKeyChecking=yes -o ConnectTimeout=10 -o BatchMode=yes
SET SSH_MAX_ATTEMPTS=3

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

REM Probes whether the remote content dir exists (hardened, no retry: a
REM failed probe safely falls back to mkdir -p, which is idempotent).
ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "if [ -d '%RemoteServerDockerContentPath%' ]; then echo 'REMOTE_DIR_EXISTS'; else echo 'REMOTE_DIR_NOT_EXISTS'; fi" | findstr /C:"REMOTE_DIR_EXISTS" >nul

IF %ERRORLEVEL%==0 (

    REM ============================
    REM REMOVE FILES ON REMOTE SERVER
    REM ============================

    CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "rm -rf %RemoteServerDockerContentPath%/*"
    IF %ERRORLEVEL% NEQ 0 (
        >&2 echo ERROR: SetContentDockerImage - remote cleanup failed.
        exit /b 1
    )

) ELSE (

    REM ============================
    REM CREATE REMOTE DIRECTORY IF IT DOES NOT EXIST
    REM ============================

    CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "mkdir -p %RemoteServerDockerContentPath%"
    IF %ERRORLEVEL% NEQ 0 (
        >&2 echo ERROR: SetContentDockerImage - remote mkdir failed.
        exit /b 1
    )

)

REM Creates the 'sh' directory on the remote server.
CALL :SSH_RUN ssh -i %SSHPrivateKeyPath% %SSH_OPTS% %SSHUser%@%SSHHost% "mkdir -p %RemoteServerDockerContentPath%/sh"
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: SetContentDockerImage - remote mkdir sh failed.
    exit /b 1
)

REM Copies the 'sh' folder to the remote server directory.
CALL :SSH_RUN scp -r -i %SSHPrivateKeyPath% %SSH_OPTS% sh\* %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%/sh
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: SetContentDockerImage - scp sh folder failed.
    exit /b 1
)

REM Copies the 'docker' application folder to the remote server directory.
CALL :SSH_RUN scp -r -i %SSHPrivateKeyPath% %SSH_OPTS% docker\* %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: SetContentDockerImage - scp docker folder failed.
    exit /b 1
)

REM Copies the runtime-generated .env file to the remote directory.
CALL :SSH_RUN scp -i %SSHPrivateKeyPath% %SSH_OPTS% docker\.env %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%/.env
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: SetContentDockerImage - scp .env failed.
    exit /b 1
)

REM Copies the 'ROOT.war' file to the remote 'docker' directory.
CALL :SSH_RUN scp -i %SSHPrivateKeyPath% %SSH_OPTS% %LocalKBEnvironmentPath%\Deploy\DOCKER\ROOT.war %SSHUser%@%SSHHost%:%RemoteServerDockerContentPath%
IF %ERRORLEVEL% NEQ 0 (
    >&2 echo ERROR: SetContentDockerImage - scp ROOT.war failed.
    exit /b 1
)

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
