pipeline {

    agent { label 'SERVER_1' }

    environment {

        /* pipelines parms */

        ForceRebuild = "${params['Force Rebuild']}" 
        DoPushApplicationGoogleCloud = "${params['Do Docker image application to Google Cloud']}"

        /* Stage 'Checking Changes' */

        GXInstallationId = 'SERVER_1_GX18U9'
        GXServerURL = "$GXServer18URL" 
        GXServerCredentialsId = 'GXServer18'
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
        ApplicationKey = '34FAA42F9416CFFD90CF9D6AA3E99A68DDF4A64702AE45B9698ABCD98EE93370'
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
        SSHPrivateKeyPath = "C:\\Users\\sa_jenkins\\.ssh\\id_ed25519"
        SSHUser = 'credential_jenkins'
        SSHHost = '10.200.200.200'
        RemoteServerDockerContentPath = "/docker/${GXServerKBName}/${WorkingEnvironment}"

        setContentDockerImageScript = '"bat\\SetContentDockerImage.bat" ' +
                                      '%LocalKBEnvironmentPath% ' +
                                      '%SSHPrivateKeyPath% ' +
                                      '%SSHUser% ' +
                                      '%SSHHost% ' +
                                      '%RemoteServerDockerContentPath%'

        DockerImageName = 'java_application_dev'
        DockerImageTag = "1.${BUILD_ID}"

        createDockerImageScript = '"bat\\CreateDockerImage.bat" ' +
                                  '%SSHPrivateKeyPath% ' +
                                  '%SSHUser% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DockerImageName% ' + 
                                  '%DockerImageTag%'

        /* Stage 'Deploy Application Docker image' */

        deployDockerImageScript = '"bat\\DeployDockerImage.bat" ' +
                                  '%SSHPrivateKeyPath% ' +
                                  '%SSHUser% ' +
                                  '%SSHHost% ' +
                                  '%RemoteServerDockerContentPath% ' +
                                  '%DockerImageTag%'

        /* Stage 'Push Application Docker image to Google Cloud' */

        ProjectId = 'java-ar-application-dev'
        Region = 'southamerica-west1'
        ServiceAccountFilePath = "/opt/gcp/java-ar-application-dev-67dff02f3ad3.json"

        pushDockerImageToGoogleCloudScript = '"bat\\PushDockerImageToGoogleCloud.bat" ' +
                                             '%SSHPrivateKeyPath% ' +
                                             '%SSHUser% ' +
                                             '%SSHHost% ' +
                                             '%RemoteServerDockerContentPath% ' +
                                             '%ProjectId% ' +
                                             '%Region% ' +
                                             '%DockerImageName% ' +
                                             '%DockerImageTag% ' +
                                             '%ServiceAccountFilePath%'

        /* Stage 'Post' */

        deleteOldDockerLocalImagesScript = '"bat\\DeleteOldDockerLocalImages.bat" ' +
                                           '%SSHPrivateKeyPath% ' +
                                           '%SSHUser% ' +
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

        stage('Create Application Docker image') {

            steps {

                echo 'Start Create Application Docker image'

                script {

                    bat label: 'Create Deploy Script',
                    script: "${env.createDeployMSBuildScript}"
                    
                    bat label: 'Create WAR file Script',
                    script: "${env.createWARFileScript}"

                    bat label: 'Set content Docker images Script',
                    script: "${env.setContentDockerImageScript}"

                    bat label: 'Create Docker Image Script',
                    script: "${env.createDockerImageScript}"

                }

                echo 'End Create Application Docker image'

            }

        }

        stage('Deploy Application Docker image') {

            steps {

                echo 'Start Deploy Application Docker image'
                script {

                    bat label: 'Deploy Script',
                    script: "${env.deployDockerImageScript}"

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

                    bat label: 'Push Application Docker image to Google Cloud Script',
                    script: "${env.pushDockerImageToGoogleCloudScript}"

                }

                echo 'End Push Application Docker image to Google Cloud'

            }

        }
        
    }

    post {

        success {

            script {

                bat label: 'Delete old Docker local images Script',
                script: "${env.deleteOldDockerLocalImagesScript}"

            }

        }

    }
    
}