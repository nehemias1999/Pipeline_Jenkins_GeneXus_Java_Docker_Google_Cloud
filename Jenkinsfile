// ==============================================================================
// Description: CI/CD pipeline GeneXus Java -> Docker -> Google Cloud.
//   Multi-env (TARGET_ENV DEV/QA/PROD) via parameters{} + ENV_CONFIG central map;
//   traceable tag MAJOR.BUILD-SHA; healthcheck deploy with automatic rollback.
// Usage: Jenkins job build with parameters (TARGET_ENV default DEV).
// Env Vars: TARGET_ENV, Force Rebuild, DoPush, NOTIFY_CHANNEL (job parameters).
// Dependencies: Jenkins plugins (gxserver, sshUserPrivateKey, gcp-sa-json),
//   bat/*.bat wrappers, docker/docker-compose.yaml on the remote host.
// ==============================================================================
/* pipeline-versioning-multienv: central per-environment resolution.
   QA/PROD never reuse DEV values (project, region, image, credentials).
   ENV_MAJOR keeps tag MAJOR.BUILD-SHA configurable per environment
   (default '1' everywhere so traceability regex ^1\.[0-9]+-[0-9a-f]{7}$ holds). */
def ENV_CONFIG = [
    DEV : [major: '1', projectId: 'java-ar-application-dev',  region: 'southamerica-west1',
           image: 'java_application_dev',  container: 'java_application_dev',
           gxCreds: 'gx-server-creds', dbUser: 'db-dev-user',  dbPass: 'db-dev-pass',
           gamUser: 'gam-db-user',     gamPass: 'gam-db-pass', workEnv: 'DEV'],
    QA  : [major: '1', projectId: 'java-ar-application-qa',   region: 'southamerica-west1',
           image: 'java_application_qa',  container: 'java_application_qa',
           gxCreds: 'gx-server-creds-qa', dbUser: 'db-qa-user',  dbPass: 'db-qa-pass',
           gamUser: 'gam-db-user-qa',     gamPass: 'gam-db-pass-qa', workEnv: 'QA'],
    PROD: [major: '1', projectId: 'java-ar-application-prod', region: 'southamerica-west1',
           image: 'java_application_prod', container: 'java_application_prod',
           gxCreds: 'gx-server-creds-prod', dbUser: 'db-prod-user',  dbPass: 'db-prod-pass',
           gamUser: 'gam-db-user-prod',     gamPass: 'gam-db-pass-prod', workEnv: 'PROD']
]
pipeline {

    agent { label 'SERVER_1' }

    /* pipeline-versioning-multienv: explicit job parameters. 'DoPush' is the
       canonical flag; 'Do Docker image application to Google Cloud' is kept as
       a legacy alias so existing job configs keep working. */
    parameters {
        choice(name: 'TARGET_ENV', choices: ['DEV', 'QA', 'PROD'],
            description: 'Target environment (resolves project/region/image/credentials from ENV_CONFIG).')
        booleanParam(name: 'Force Rebuild', defaultValue: false,
            description: 'Force GeneXus KB rebuild even without changes.')
        booleanParam(name: 'DoPush', defaultValue: false,
            description: 'Push the Docker image to Google Cloud Artifact Registry.')
        booleanParam(name: 'Do Docker image application to Google Cloud', defaultValue: false,
            description: 'Legacy alias of DoPush (kept for backward compatibility).')
        string(name: 'NOTIFY_CHANNEL', defaultValue: 'mail',
            description: "Traceability notification channel: 'mail' (default) or 'slack'.")
    }

    environment {

        /* pipelines parms */

        ForceRebuild = "${params['Force Rebuild']}" 
        DoPushApplicationGoogleCloud = "${params['Do Docker image application to Google Cloud']}"

        /* Stage 'Checking Changes' */

        GXInstallationId = 'SERVER_1_GX18U9'
        GXServerURL = "$GXServer18URL" 
        GXServerCredentialsId = 'gx-server-creds'
        GXServerKBName = 'java_application'
        GXServerKBVersion = 'development'
        WorkingDirectory = "C:\\applications\\java_application"
        WorkingVersion = 'development'
        KBDBServerInstance = "DB_SERVER_1\\SQLEXPRESS"

        /* Stage 'Build KB' */

        MSBuildPath = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin"
        Genexus18U9Path = "C:\\Program Files (x86)\\GeneXus\\GeneXus18U9"
        WorkingEnvironment = 'DEV'
        CompileMains = 'true'

        buildMSBuildScript = '"%MSBuildPath%\\MSBuild.exe" "%Genexus18U9Path%\\TeamDev.msbuild" ' +
                             '/p:GX_PROGRAM_DIR="%Genexus18U9Path%" ' +
                             '/p:WorkingDirectory=%WorkingDirectory% ' +
                             '/p:DbaseServerUsername=%GXServerUserName% ' +
                             '/p:DbaseServerPassword=%GXServerPassword% ' +
                             '/p:WorkingVersion=%WorkingVersion% ' +
                             '/p:WorkingEnvironment=%WorkingEnvironment% ' +
                             '/p:ForceRebuild=%ForceRebuild% ' + 
                             '/p:CompileMains=%CompileMains% ' +
                             '/t:Build' 

        WorkingKBWebPath = "${WorkingDirectory}\\${WorkingEnvironment}\\web"

        /* Stage 'Create Application Docker image' */

        ExtraMSBuildPath = "${Genexus18U9Path}\\ApplicationServers\\Templates\\JavaWeb\\msbuild\\TomcatContextSettings.msbuild"
        /* pipeline-security: ApplicationKey comes from the 'gx-application-key'
           secret-text credential (masked **** in logs), never a literal. */
        ApplicationKey = credentials('gx-application-key')
        TargetJRE = '9'
        DeployTarget = "${Genexus18U9Path}\\DeploymentTargets\\Docker\\docker.targets"
        PackageFormat = 'Automatic'
        Timestamp = 'JAVA_APPLICATION_DEV'
        DeploymentUnit = 'JAVA_APPLICATION_DU'
        TargetID = 'DOCKER'
        ApplicationServer = 'Tomcat 10.1'
        ProjectName = 'JAVA_APPLICATION_DEV'
        IncludeGAM = 'true'
        IncludeGXFlowBackoffice = 'false'
        EnableKBN = 'false'
        APPUpdate = 'NONE'
        DeployFullPath = "${WorkingKBWebPath}"
        DeployType = 'BINARIES'

        createDeployMSBuildScript = '"%MSBuildPath%\\MSBuild.exe" "%Genexus18U9Path%\\Deploy.msbuild" ' + 
                                    '/p:KBPath="%WorkingDirectory%" ' + 
                                    '/p:KBVersion="%WorkingVersion%" ' +
                                    '/p:KBEnvironment="%WorkingEnvironment%" ' + 
                                    '/p:EXTRA_MSBUILD="%ExtraMSBuild%" ' + 
                                    '/p:APPLICATION_KEY="%ApplicationKey%" ' +
                                    '/p:TARGET_JRE="%TargetJRE%" ' + 
                                    '/p:DEPLOY_TARGETS="%DeployTarget%" ' +
                                    '/p:PACKAGE_FORMAT="%PackageFormat%" ' +
                                    '/p:TimeStamp=%Timestamp% ' + 
                                    '/p:DeploymentUnit=%DeploymentUnit% ' +
                                    '/p:TargetId="%TargetID%" ' + 
                                    '/p:ApplicationServer="%ApplicationServer%" ' +  
                                    '/p:ProjectName="%ProjectName%" ' +
                                    '/p:INCLUDE_GAM="%IncludeGAM%" ' + 
                                    '/p:INCLUDE_GXFLOW_BACKOFFICE="%IncludeGXFlowBackoffice%" ' +
                                    '/p:ENABLE_KBN="%EnableKBN%" ' +
                                    '/p:APP_UPDATE="%APPUpdate%" ' + 
                                    '/p:OutputPath="%DeployFullPath%" ' + 
                                    '/p:DEPLOY_TYPE="%DeployType%" ' + 
                                    '/t:CreateDeploy' 
                                     
        OutputGXDPROJFilePath = "${WorkingKBWebPath}"
        GXDPROJFilePath = "${OutputGXDPROJFilePath}\\${ProjectName}.gxdproj"

        createWARFileScript = '"%MSBuildPath%\\MSBuild.exe" ' +
                              '%GXDPROJFilePath%'

        LocalKBEnvironmentPath = "${WorkingDirectory}\\${WorkingEnvironment}"
        /* pipeline-security: SSH key/user are injected at runtime from the
           'jenkins-ssh-key' sshUserPrivateKey binding (SSH_KEY_FILE/SSH_USER).
           SSHHost is non-secret infra config. No key paths or users hardcoded. */
        SSHHost = '10.200.200.200'
        RemoteServerDockerContentPath = "/docker/${GXServerKBName}/${WorkingEnvironment}"

        /* pipeline-security: non-secret DB endpoints for runtime .env
           generation; passwords come from credentials bindings only. */
        DbUrl = '10.200.200.200'
        DbSchema = 'java_application'
        GamDbUrl = '10.200.200.200'
        GamDbSchema = 'java_application_gam'

        setContentDockerImageScript = '"bat\\SetContentDockerImage.bat" ' +
                                      '%LocalKBEnvironmentPath% ' +
                                      '%SSH_KEY_FILE% ' +
                                      '%SSH_USER% ' +
                                      '%SSHHost% ' +
                                      '%RemoteServerDockerContentPath%'

        DockerImageName = 'java_application_dev'
        /* pipeline-traceability: traceable tag 1.BUILD_NUMBER-sha7.
           DOCKER_IMAGE_TAG = "1.${BUILD_NUMBER}-${GIT_SHA7}" where GIT_SHA7
           is the short (7-char) form of GIT_SHA (git rev-parse HEAD,
           fallback env GIT_COMMIT). Resolved + validated against
           ^1\.[0-9]+-[0-9a-f]{7}$ in stage 'Resolve Traceability Metadata';
           legacy tags without SHA fail fast with an actionable message. */
        GIT_SHA = "${env.GIT_COMMIT ?: ''}"
        GIT_SHA7 = 'unknown'
        DOCKER_IMAGE_TAG = "1.${BUILD_NUMBER}-${GIT_SHA7}"
        IMAGE_CREATED = ''
        FULL_IMAGE = ''

        /* pipeline-traceability: OCI labels applied at build time
           (org.opencontainers.image.revision/version/created/source);
           see CreateDockerImage.bat which passes them to docker build. */
        createDockerImageScript = '"bat\\CreateDockerImage.bat" ' +
                                  '%SSH_KEY_FILE% ' +
                                  '%SSH_USER% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DockerImageName% ' +
                                  '%DOCKER_IMAGE_TAG% ' +
                                  '%GIT_SHA% ' +
                                  '%IMAGE_CREATED% ' +
                                  '%GIT_URL%'

        /* Stage 'Deploy Application Docker image'
           pipeline-versioning-multienv: passes the per-env container name so
           the wrapper can healthcheck the right container; the wrapper keeps
           the previous tag and rolls back automatically on healthcheck failure
           (non-zero exit marks the build FAILURE). */

        deployDockerImageScript = '"bat\\DeployDockerImage.bat" ' +
                                  '%SSH_KEY_FILE% ' +
                                  '%SSH_USER% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DOCKER_IMAGE_TAG% ' +
                                  '%DockerContainerName%'

        /* Stage 'Push Application Docker image to Google Cloud' */

        ProjectId = 'java-ar-application-dev'
        Region = 'southamerica-west1'
        /* pipeline-security: SA JSON comes from the 'gcp-sa-json' file
           credential (GCP_SA_KEY) at runtime; never a hardcoded JSON path. */

        pushDockerImageToGoogleCloudScript = '"bat\\PushDockerImageToGoogleCloud.bat" ' +
                                             '%SSH_KEY_FILE% ' +
                                             '%SSH_USER% ' +
                                             '%SSHHost% ' +
                                             '%RemoteServerDockerContentPath% ' +
                                             '%ProjectId% ' +
                                             '%Region% ' +
                                              '%DockerImageName% ' +
                                              '%DOCKER_IMAGE_TAG% ' +
                                              '%GCP_SA_KEY%'

        /* Stage 'Post' */

        deleteOldDockerLocalImagesScript = '"bat\\DeleteOldDockerLocalImages.bat" ' +
                                           '%SSH_KEY_FILE% ' +
                                           '%SSH_USER% ' +
                                           '%SSHHost% ' +
                                           '%RemoteServerDockerContentPath%'

    }

    stages {

        stage('Resolve Environment Config') {

            steps {

                echo 'Start Resolve Environment Config'

                script {

                    /* pipeline-versioning-multienv: single source of per-env
                       config; DEV stays the default so merged security (PR #1)
                       and traceability (PR #2) behavior is unchanged. */
                    def target = (params?.TARGET_ENV ?: 'DEV').toString().toUpperCase()
                    def cfg = ENV_CONFIG[target] ?: ENV_CONFIG['DEV']
                    env.TARGET_ENV = target
                    env.ENV_MAJOR = cfg.major
                    env.ProjectId = cfg.projectId
                    env.Region = cfg.region
                    env.DockerImageName = cfg.image
                    env.DockerContainerName = cfg.container
                    env.WorkingEnvironment = cfg.workEnv
                    env.GXServerCredentialsId = cfg.gxCreds
                    env.DbUserCredId = cfg.dbUser
                    env.DbPassCredId = cfg.dbPass
                    env.GamDbUserCredId = cfg.gamUser
                    env.GamDbPassCredId = cfg.gamPass
                    echo "Environment: TARGET_ENV=${env.TARGET_ENV} project=${env.ProjectId} region=${env.Region} image=${env.DockerImageName} major=${env.ENV_MAJOR}"

                }

                echo 'End Resolve Environment Config'

            }

        }

        stage('Resolve Traceability Metadata') {

            steps {

                echo 'Start Resolve Traceability Metadata'

                script {

                    /* pipeline-traceability: single source of commit->WAR->
                       image->deploy provenance. Rejects legacy tags without
                       SHA so untraceable artifacts never reach the registry. */
                    def sha = (env.GIT_COMMIT ?: '').trim()
                    if (!sha) {
                        sha = bat(label: 'Resolve GIT_SHA', returnStdout: true,
                            script: '@git rev-parse HEAD').trim().readLines().last().trim()
                    }
                    env.GIT_SHA = sha
                    env.GIT_SHA7 = sha.take(7)
                    /* pipeline-versioning-multienv: MAJOR.BUILD-SHA, MAJOR from
                       ENV_CONFIG (default '1'); legacy tags without SHA are
                       rejected here, before any build/push/registry step. */
                    env.DOCKER_IMAGE_TAG = "${env.ENV_MAJOR ?: '1'}.${env.BUILD_NUMBER}-${env.GIT_SHA7}"
                    env.IMAGE_CREATED = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))
                    env.FULL_IMAGE = "${env.Region}-docker.pkg.dev/${env.ProjectId}/docker/${env.DockerImageName}:${env.DOCKER_IMAGE_TAG}"
                    if (env.DOCKER_IMAGE_TAG ==~ /^[0-9]+\.[0-9]+$/) {
                        error "ACTIONABLE: legacy tag '${env.DOCKER_IMAGE_TAG}' rejected - expected MAJOR.<BUILD_NUMBER>-<sha7> (e.g. ${env.ENV_MAJOR ?: '1'}.42-abc1234). Tags without the SHA suffix are untraceable; check git checkout / GIT_COMMIT."
                    }
                    if (!(env.DOCKER_IMAGE_TAG ==~ /^1\.[0-9]+-[0-9a-f]{7}$/)) {
                        error "ACTIONABLE: legacy tag '${env.DOCKER_IMAGE_TAG}' rejected - expected 1.<BUILD_NUMBER>-<sha7> (e.g. 1.42-abc1234). Check git checkout / GIT_COMMIT."
                    }
                    if (!(env.GIT_SHA ==~ /^[0-9a-f]{40}$/)) {
                        error "ACTIONABLE: GIT_SHA '${env.GIT_SHA}' is not a 40-char commit SHA. Check git checkout."
                    }
                    currentBuild.description = "env:${env.WorkingEnvironment} tag:${env.DOCKER_IMAGE_TAG} sha:${env.GIT_SHA} kb:${env.WorkingVersion}"
                    echo "Provenance: tag=${env.DOCKER_IMAGE_TAG} sha=${env.GIT_SHA} created=${env.IMAGE_CREATED} image=${env.FULL_IMAGE}"

                }

                echo 'End Resolve Traceability Metadata'

            }

        }

        stage('Checking Changes') {

            steps {

                echo 'Start Checking Changes'

                    gxserver changelog: true, poll: true,
                        gxInstallationId: "${env.GXInstallationId}",
                        serverURL: "${env.GXServerURL}",
                        credentialsId: "${env.GXServerCredentialsId}",
                        kbName: "${env.GXServerKBName}",
                        kbVersion: "${env.GXServerKBVersion}", 
                        localKbPath: "${env.WorkingDirectory}",
                        localKbVersion: "${env.WorkingVersion}",
                        kbDbServerInstance: "${env.KBDBServerInstance}",
                        kbDbInSameFolder: false

                echo 'End Checking Changes'

            }

        }

        stage('Build KB') {

            steps {

                echo 'Start Build KB'

                script {

                    withCredentials([usernamePassword(credentialsId: "${env.GXServerCredentialsId}", usernameVariable: 'GXServerUserName', passwordVariable: 'GXServerPassword')]) {

                        bat label: 'Build KB Script',
                        script: "${env.buildMSBuildScript}"

                    }

                }

                echo 'End Build KB'

            }

        }

        stage('Prepare Runtime Env') {

            steps {

                echo 'Start Prepare Runtime Env'

                script {

                    /* pipeline-security: docker/.env is generated at runtime
                       from non-secret env config + credentials bindings and is
                       never versioned (see .gitignore). %VAR% expands in
                       cmd.exe, so secret VALUES never appear in console logs
                       (Jenkins masks them as **** regardless). */
                    /* pipeline-versioning-multienv: per-env credential IDs resolved
                       from ENV_CONFIG (DEV defaults preserve PR #1 behavior). */
                    withCredentials([
                        string(credentialsId: "${env.DbUserCredId ?: 'db-dev-user'}", variable: 'DB_USER'),
                        string(credentialsId: "${env.DbPassCredId ?: 'db-dev-pass'}", variable: 'DB_PASS'),
                        string(credentialsId: "${env.GamDbUserCredId ?: 'gam-db-user'}", variable: 'GAM_DB_USER'),
                        string(credentialsId: "${env.GamDbPassCredId ?: 'gam-db-pass'}", variable: 'GAM_DB_PASS')
                    ]) {

                        bat label: 'Generate runtime .env',
                        script: '''@echo off
echo DOCKER_IMAGE_NAME=%DockerImageName%> docker\\.env
echo DOCKER_IMAGE_TAG=%DOCKER_IMAGE_TAG%>> docker\\.env
echo DOCKER_CONTAINER_NAME=%DockerImageName%>> docker\\.env
echo.>> docker\\.env
echo DB_URL=%DbUrl%>> docker\\.env
echo DB_SCHEMA=%DbSchema%>> docker\\.env
echo DB_USER=%DB_USER%>> docker\\.env
echo DB_PASSWORD=%DB_PASS%>> docker\\.env
echo.>> docker\\.env
echo GAM_DB_URL=%GamDbUrl%>> docker\\.env
echo GAM_DB_SCHEMA=%GamDbSchema%>> docker\\.env
echo GAM_DB_USER=%GAM_DB_USER%>> docker\\.env
echo GAM_DB_PASSWORD=%GAM_DB_PASS%>> docker\\.env'''

                    }

                }

                echo 'End Prepare Runtime Env'

            }

        }

        stage('Create Application Docker image') {

            steps {

                echo 'Start Create Application Docker image'

                script {

                    bat label: 'Create Deploy Script',
                    script: "${env.createDeployMSBuildScript}"
                    
                    bat label: 'Create WAR file Script',
                    script: "${env.createWARFileScript}"

                    /* pipeline-traceability: sha256sum ROOT.war | tee war.sha256
                       (Git Bash when available, PowerShell Get-FileHash
                       fallback); war.sha256 is archived + fingerprinted so the
                       deployed WAR is auditable from the build page. */
                    bat label: 'Fingerprint WAR (sha256)',
                    script: '''@echo off
where sha256sum >nul 2>&1
if %ERRORLEVEL%==0 (sha256sum "%DeployFullPath%\\ROOT.war" | tee war.sha256) else (powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 $env:DeployFullPath\\ROOT.war | ForEach-Object { $_.Hash.ToLower() + '  ROOT.war' } | Tee-Object -FilePath war.sha256")
type war.sha256'''

                    /* pipeline-security: SSH key/user from binding; the .bat
                       wrappers enforce StrictHostKeyChecking/ConnectTimeout/
                       BatchMode + retries and exit 1 on failure. */
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {

                        bat label: 'Set content Docker images Script',
                        script: "${env.setContentDockerImageScript}"

                        bat label: 'Create Docker Image Script',
                        script: "${env.createDockerImageScript}"

                    }

                }

                echo 'End Create Application Docker image'

            }

        }

        stage('Deploy Application Docker image') {

            steps {

                echo 'Start Deploy Application Docker image'
                script {

                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {

                        bat label: 'Deploy Script',
                        script: "${env.deployDockerImageScript}"

                    }

                }

                echo 'End Deploy Application Docker image'

            }

        }

        stage('Push Application Docker image to Google Cloud') {

            when {
                /* DoPush canonical param or legacy alias (env flag or param). */
                expression { params['DoPush'] == true || env.DoPushApplicationGoogleCloud == 'true' }
            }

            steps {

                echo 'Start Push Application Docker image to Google Cloud'

                script {

                    /* pipeline-security: SA JSON via file credential; the key
                       FILE path (GCP_SA_KEY) is passed, never key content. */
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER'),
                        file(credentialsId: 'gcp-sa-json', variable: 'GCP_SA_KEY')
                    ]) {

                        bat label: 'Push Application Docker image to Google Cloud Script',
                        script: "${env.pushDockerImageToGoogleCloudScript}"

                    }

                }

                echo 'End Push Application Docker image to Google Cloud'

            }

        }
        
    }

    post {

        always {

            /* pipeline-traceability: provenance archived on every build;
               fingerprint links WAR + compose + env template to this run. */
            archiveArtifacts artifacts: 'war.sha256, docker/docker-compose.yaml, docker/.env.template', fingerprint: true, allowEmptyArchive: true

        }

        success {

            script {

                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {

                    bat label: 'Delete old Docker local images Script',
                    script: "${env.deleteOldDockerLocalImagesScript}"

                }

                /* pipeline-traceability: auditable success notice with links
                   to the build, the traceable image tag and its digest. */
                notifyTraceability('SUCCESS')

            }

        }

        failure {

            script {

                /* pipeline-traceability: auditable failure notice (stage name
                   when available, commit, log link) via NOTIFY_CHANNEL. */
                notifyTraceability('FAILURE')

            }

        }

    }

}

/* pipeline-traceability: sends the build notice via mail (default) or Slack
   according to NOTIFY_CHANNEL (job parameter or environment, 'mail'|'slack').
   Includes BUILD_URL, FULL_IMAGE + digest reference, tag, commit and env so
   every artifact stays traceable from the notification itself. */
def notifyTraceability(String result) {
    def channel = (params?.NOTIFY_CHANNEL ?: env.NOTIFY_CHANNEL ?: 'mail').toString().toLowerCase()
    def subject = "${result} ${env.JOB_NAME} #${env.BUILD_NUMBER} tag=${env.DOCKER_IMAGE_TAG}"
    def body = """Result: ${result}
Job: ${env.JOB_NAME} #${env.BUILD_NUMBER}
Env: ${env.WorkingEnvironment}
Tag: ${env.DOCKER_IMAGE_TAG}
Commit: ${env.GIT_SHA}
KB: ${env.WorkingVersion}
Build: ${env.BUILD_URL}
Image: ${env.FULL_IMAGE} (digest in push log, 'DIGEST:' line)"""
    try {
        if (channel == 'slack') {
            slackSend color: result == 'SUCCESS' ? 'good' : 'danger', message: "${subject}\n${body}"
        } else {
            emailext subject: subject, body: body, recipientProviders: [[$class: 'RequesterRecipientProvider']]
        }
    } catch (err) {
        echo "WARN: traceability notification via '${channel}' failed: ${err.getMessage()}"
    }
}