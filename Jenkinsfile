pipeline {

    agent { label 'SERVER_1' }

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
        DockerImageTag = "1.${BUILD_ID}"

        createDockerImageScript = '"bat\\CreateDockerImage.bat" ' +
                                  '%SSH_KEY_FILE% ' +
                                  '%SSH_USER% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DockerImageName% ' + 
                                  '%DockerImageTag%'

        /* Stage 'Deploy Application Docker image' */

        deployDockerImageScript = '"bat\\DeployDockerImage.bat" ' +
                                  '%SSH_KEY_FILE% ' +
                                  '%SSH_USER% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DockerImageTag%'

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
                                             '%DockerImageTag% ' +
                                             '%GCP_SA_KEY%'

        /* Stage 'Post' */

        deleteOldDockerLocalImagesScript = '"bat\\DeleteOldDockerLocalImages.bat" ' +
                                           '%SSH_KEY_FILE% ' +
                                           '%SSH_USER% ' +
                                           '%SSHHost% ' +
                                           '%RemoteServerDockerContentPath%'

    }

    stages {

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
                    withCredentials([
                        string(credentialsId: 'db-dev-user', variable: 'DB_USER'),
                        string(credentialsId: 'db-dev-pass', variable: 'DB_PASS'),
                        string(credentialsId: 'gam-db-user', variable: 'GAM_DB_USER'),
                        string(credentialsId: 'gam-db-pass', variable: 'GAM_DB_PASS')
                    ]) {

                        bat label: 'Generate runtime .env',
                        script: '''@echo off
echo DOCKER_IMAGE_NAME=%DockerImageName%> docker\\.env
echo DOCKER_IMAGE_TAG=%DockerImageTag%>> docker\\.env
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
                expression { env.DoPushApplicationGoogleCloud == 'true' }
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

        success {

            script {

                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {

                    bat label: 'Delete old Docker local images Script',
                    script: "${env.deleteOldDockerLocalImagesScript}"

                }

            }

        }

    }
    
}