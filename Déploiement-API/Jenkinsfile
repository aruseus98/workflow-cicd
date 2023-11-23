pipeline {
    agent any

    tools {
        nodejs 'nodejs'
    }

    stages {

        stage('Initialize'){
            steps{
                script{
                    // Déclaration et initialisation des variables ici
                    def currentBranch = env.BRANCH_NAME ?: 'dev' 
                    def buildNumber = env.BUILD_NUMBER
                    def folderName = (currentBranch == 'main') ? 'the-tiptop-api' :
                                     (currentBranch == 'preprod') ? 'the-tiptop-api-preprod' :
                                     'the-tiptop-api-dev' 

                    def dockerFileBuild = (currentBranch == 'main') ? 'Dockerfile.prod' :
                                          (currentBranch == 'preprod') ? 'Dockerfile.preprod' :
                                          'Dockerfile.dev' 

                    echo "Current branch: ${currentBranch}"
                    echo "Folder name set to: ${folderName}"
                    echo "Build number set to : ${buildNumber}"
                    env.dockerFileBuild = dockerFileBuild
                    echo "Utilisation du dockerfile suivant: ${env.dockerFileBuild}"

                    // Enregistrer les variables pour utilisation dans les stages suivants
                    env.folderName = folderName
                    env.currentBranch = currentBranch
                }
            }
        }

        stage('Clone Repository') {
            steps {
                    
                // Cloner le référentiel GitLab pour l'application Angular dans le sous-dossier 'angular'
                dir("${WORKSPACE}/") {
                    script {
                        if (!fileExists(env.folderName)) {
                            sh "mkdir ${env.folderName}"
                            echo "Workspace : ${WORKSPACE}/${env.folderName}"
                            dir("${WORKSPACE}/${env.folderName}") {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.currentBranch}"]],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [[$class: 'CleanCheckout']],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'the-tiptop-api-repo-token', url: 'https://gitlab.dsp-archiwebo22b-ji-rw-ah.fr/dev/the-tiptop-api']]])
                            }
                        } else {
                            echo "Le dossier '${env.folderName}' existe déjà."
                            dir("${WORKSPACE}/${env.folderName}") {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.currentBranch}"]],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [[$class: 'CleanCheckout']],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'the-tiptop-api-repo-token', url: 'https://gitlab.dsp-archiwebo22b-ji-rw-ah.fr/dev/the-tiptop-api']]])
                            }
                        }
                    }
                }

            }
        }

        stage('Setup') {
            steps {
                script {
                    // Lisez les métadonnées une fois au début
                    metadata = readYaml(file: "${env.folderName}/project-metadata.yaml")
                }
            }
        }


        stage('Run tests with Mocha & Chai') {
             steps {
                script{
                    switch(metadata.language) {
                        case 'NodeJS':
                            echo "Installation des dépendances"
                            dir("${WORKSPACE}/${env.folderName}") {
                                sh "npm install" // Installation des dépendances npm
                            }
                            echo "Lancement des tests avec Mocha & Chai"
                            dir("${WORKSPACE}/${env.folderName}") {
                                echo "Vérification du répertoire de travail"
                                sh 'pwd' // Imprime le répertoire de travail actuel
                                sh 'ls -la' // Liste tous les fichiers et dossiers dans le répertoire courant
                                sh 'ls -la tests'
                                sh "npm test" // Exécution des tests mocha pour l'API dans le workdir
                            }
                            break
                        
                        default:
                            echo "echo Aucune étape de compilation requise ou langage non reconnu"
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Analyse SonarQube pour API"
                dir("${WORKSPACE}/${env.folderName}") {
                    withCredentials([string(credentialsId: 'SonarQubeApi', variable: 'SONAR_TOKEN')]) {
                        // Afficher la valeur de WORKSPACE
                        echo "WORKSPACE est : ${WORKSPACE}"

                        withSonarQubeEnv('SonarQube') {
                            script {
                                def scannerHome = tool name: 'SonarQubeApi'
                                echo "scannerHome est : ${scannerHome}"
                                // Afficher le chemin d'accès de Sonar
                                echo "PATH+SONAR est : ${scannerHome}/bin"
                                withEnv(["PATH+SONAR=${scannerHome}/bin"]) {
                                    sh "sonar-scanner \
                                        -Dsonar.host.url=https://sonarqube.dsp-archiwebo22b-ji-rw-ah.fr/ \
                                        -Dsonar.login=${SONAR_TOKEN}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Create Docker Image') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    // Créer une image Docker pour l'API
                    def apiImageName = "${env.folderName}:${buildNumber}"
                    dir("${WORKSPACE}/${env.folderName}") {
                        sh "docker build -t ${apiImageName} -f ${env.dockerFileBuild} ."
                    }
                }
            }
        }

        stage('Deploy Docker Image') {
            steps {
                script {
                    // Obtenir le numéro de build Jenkins
                    def buildNumber = env.BUILD_NUMBER
                    // Définir le nom du conteneur en fonction de la branche actuelle
                    def containerName = (env.currentBranch == 'dev') ? "api-dev" :
                                        (env.currentBranch == 'preprod') ? "api-preprod" :
                                        (env.currentBranch == 'main') ? "api-prod" :
                                        "api-unknown" // Valeur par défaut ou pour les branches non spécifiées

                    echo "Container Name: ${containerName}"

                    // Enregistrer les variables pour utilisation dans les stages suivants
                    env.containerName = containerName

                    // Supprimer l'ancien conteneur, s'il existe
                    def ApiContainerExists = sh(script: "docker ps -a | grep -w ${containerName}", returnStatus: true) == 0
                    if (ApiContainerExists) {
                        sh "docker stop ${containerName}"
                        sh "docker rm ${containerName}"
                    }

                    // Récupérer l'ID de l'image actuellement utilisée par le conteneur
                    echo "----==>>> Récupérer l'ID de l'image actuellement utilisée par le conteneur"
                    def currentImageId = sh(script: "docker ps -a --filter 'name=${containerName}' --format '{{.Image}}'", returnStdout: true).trim()

                    if (currentImageId) {
                        // Supprimer l'image
                        echo "----==>>> Suppréssion de l'image"
                        sh "docker rmi ${currentImageId} -f"
                    }

                    // Construire et démarrer le conteneur avec docker-compose tout en créant une nouvelle image
                    echo "----==>>> Démarrage du container avec le chemin '/usr/local/bin/docker-compose' tout en créant une nouvelle image"
                    sh "WORKSPACE_PATH=${WORKSPACE} /usr/local/bin/docker-compose -f /home/debian/docker-compose.yml up -d ${containerName} --build"
                }
            }
        }

        stage('Backup Docker Image to Docker Hub') {
            steps {
                script {
                    // Récupère la date et l'heure
                    def currentDate = sh(script: "date '+%d-%m-%Y-%Hh%M'", returnStdout: true).trim()

                    // Authentification à Docker Hub
                    def dockerHubCredentialsId = 'fducks196' 
                    withDockerRegistry([credentialsId: dockerHubCredentialsId, url: 'https://index.docker.io/v1/']) {

                        // Nom d'utilisateur Docker Hub et nom du repo
                        def dockerHubUsername = 'fducks196'
                        def dockerRepoName = 'backup-api'

                        // Nom de l'image originale basée sur le numéro de build
                        def imageName = "${env.folderName}:${env.BUILD_NUMBER}"
                        
                        // Nom de l'image pour Docker Hub basé sur la date
                        def dockerHubImageName = "${dockerHubUsername}/${dockerRepoName}:${env.containerName}-${currentDate}"
                        
                        // Tagger l'image originale avec le nom destiné à Docker Hub
                        sh "docker tag ${imageName} ${dockerHubImageName}"

                        // Pousser (push) l'image vers Docker Hub avec le tag basé sur la date
                        sh "docker push ${dockerHubImageName}"
                    }
                }
            }
        }


        stage('Succès') {
            steps {
                echo "Réussi"
            }
        }
    }
}

