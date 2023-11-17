def metadata

pipeline {
    agent any

    environment {
        CHROME_BIN = ''
    }

    tools {
        nodejs 'nodejs'
    }

    stages {
        stage('Initialize'){
            steps{
                script{
                    // Déclaration et initialisation des variables ici
                    def currentBranch = env.BRANCH_NAME ?: 'dev' 
                    def folderName = (currentBranch == 'main') ? 'prod-angular' :
                                     (currentBranch == 'preprod') ? 'preprod-angular' :
                                     'angular' 

                    echo "Current branch: ${currentBranch}"
                    echo "Folder name set to: ${folderName}"

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

                        // Afficher la branche qui sera clonée
                        echo "Cloning branch: ${env.currentBranch}"

                        if (!fileExists(env.folderName)) {
                            sh "mkdir ${env.folderName}"
                            echo "Workspace : ${WORKSPACE}/${env.folderName}"
                            dir("${WORKSPACE}/${env.folderName}") {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.currentBranch}"]],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [[$class: 'CleanCheckout']],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'the-tiptop-front-repo-token', url: 'https://gitlab.dsp-archiwebo22b-ji-rw-ah.fr/dev/the-tiptop-front/']]])
                            }
                        } else {
                            echo "Le dossier '${env.folderName}' existe déjà."
                            dir("${WORKSPACE}/${env.folderName}") {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.currentBranch}"]],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [[$class: 'CleanCheckout']],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'the-tiptop-front-repo-token', url: 'https://gitlab.dsp-archiwebo22b-ji-rw-ah.fr/dev/the-tiptop-front/']]])
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

        stage('Install Dependencies') {
            steps {
                script {
                    switch (metadata.language) {
                        case 'PHP':
                            echo "Install PHP"
                            //sh 'composer install'
                            break
                        case 'NodeJS':                            
                            echo "Install Angular"
                            dir("${WORKSPACE}/${env.folderName}") {
                                sh 'npm install'
                            }
                            break
                        case 'Python':
                            echo "Install Python"
                            //sh 'pip install -r requirements.txt'
                            break
                        case 'Ruby':
                            echo "Install Ruby"
                            //sh 'bundle install'
                            break
                        // ... autres cas pour d'autres langages ou frameworks
                        default:
                            echo "Aucune étape de compilation requise ou langage non reconnu"
                    }
                }
            }
        }
        stage('Compilation') {
            steps {
                script {
                    switch (metadata.language) {
                        case 'PHP':
                            echo "Build PHP"
                            break
                        case 'NodeJS':                            
                            echo "Build Angular"
                            dir("${WORKSPACE}/${env.folderName}") {
                                sh 'npm run build'
                            }
                            break
                        case 'Python':
                            echo "Build Python"
                            break
                        case 'Ruby':
                            echo "Build Ruby"
                            break
                        // ... autres cas pour d'autres langages ou frameworks
                        default:
                            echo "Aucune étape de compilation requise ou langage non reconnu"
                    }
                }
            }
        }

        stage('Determine Chrome Path - For Kama tests') {
            steps {
                script {
                    dir("${WORKSPACE}/${env.folderName}") {
                        CHROME_BIN = sh(script: 'node getChromePath.js', returnStdout: true).trim()
                        echo "Detected Chrome path: ${CHROME_BIN}"
                    }
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    switch (metadata.language) {
                        case 'NodeJS':
                            echo "Run Angular Unit Tests"
                            dir("${WORKSPACE}/${env.folderName}") {
                                withEnv(["CHROME_BIN=${CHROME_BIN}"]) {
                                    // Imprimer le répertoire actuel
                                    sh 'pwd'
                                    // Lister le contenu du répertoire
                                    sh 'ls -la'
                                    sh 'npm run test:unit' // Pour lancer les tests unitaires
                                }
                                def coverageExists = sh(script: 'ls -l | grep coverage || echo "Coverage directory not found."', returnStatus: true)
                                if (coverageExists == 0) {
                                    echo "--- Coverage directory exists ---"
                                    sh 'cat coverage/lcov.info || echo "lcov.info file not found"'
                                } else {
                                    echo "--- Coverage directory not found ---"
                                }
                            }
                            break
                        default:
                            echo "No unit tests required or language not recognized"
                    }
                }
            }
        }

        stage('Run Integration Tests') {
            steps {
                script {
                    switch (metadata.language) {
                        case 'NodeJS':
                            echo "Run Angular Integration Tests"
                            dir("${WORKSPACE}/${env.folderName}") {
                                withEnv(["CHROME_BIN=${CHROME_BIN}"]) {
                                    sh 'npm run test:integration' // Pour lancer les tests d'intégrations
                                }
                                def coverageExists = sh(script: 'ls -l | grep coverage || echo "Coverage directory not found."', returnStatus: true)
                                if (coverageExists == 0) {
                                    echo "--- Coverage directory exists ---"
                                    sh 'cat coverage/lcov.info || echo "lcov.info file not found"'
                                } else {
                                    echo "--- Coverage directory not found ---"
                                }
                            }
                            break
                        default:
                            echo "No integration tests required or language not recognized"
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    switch (metadata.language) {
                        case 'NodeJS':                            
                            echo "Analyse SonarQube pour Angular TEST"
                            dir("${WORKSPACE}/${env.folderName}") {
                                withCredentials([string(credentialsId: 'angular-sonar', variable: 'SONAR_TOKEN')]) {
                                    // Afficher la valeur de WORKSPACE
                                    echo "WORKSPACE est : ${WORKSPACE}"
                                    
                                    // Utilisez withSonarQubeEnv avec le nom de votre configuration SonarQube
                                    withSonarQubeEnv('SonarQube') {
                                        // Afficher les informations de l'outil SonarQube
                                        def scannerHome = tool name: 'SonarQube'
                                        echo "scannerHome est : ${scannerHome}"
                                        
                                        // Afficher le chemin d'accès de Sonar
                                        echo "PATH+SONAR est : ${scannerHome}/bin"
                                        
                                        withEnv(["PATH+SONAR=${scannerHome}/bin"]) {
                                            sh "sonar-scanner \
                                                -Dsonar.host.url=http://sonarqube.dsp-archiwebo22b-ji-rw-ah.fr/ \
                                                -Dsonar.login=${SONAR_TOKEN}"
                                        }
                                    }
                                }
                            }
                            break
                        // ... autres cas
                        default:
                            echo "Aucune analyse SonarQube requise ou langage non reconnu"
                    }
                }
            }
        }

        stage('Create Docker Image') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    // Créer une image Docker pour l'application Angular
                    def angularImageName = "${env.folderName}:${buildNumber}"
                    dir("${WORKSPACE}/${env.folderName}") {
                        sh "docker build -t ${angularImageName} ."
                    }
                }
            }
        }

        stage('Deploy Angular Docker Image') {
            steps {
                script {
                    // Obtenir le numéro de build Jenkins
                    def buildNumber = env.BUILD_NUMBER
        
                    // Nom du conteneur pour l'application Angular
                    // Définir le nom du conteneur en fonction de la branche actuelle
                    def containerName = (env.currentBranch == 'dev') ? "angular-dev" :
                                       (env.currentBranch == 'preprod') ? "angular-preprod" :
                                       (env.currentBranch == 'main') ? "prod-angular" :
                                       "angular-unknown" // Valeur par défaut ou pour les branches non spécifiées

                    echo "Container Name: ${containerName}"

                    // Enregistrer les variables pour utilisation dans les stages suivants
                    env.containerName = containerName
        
                    // Supprimer l'ancien conteneur, s'il existe
                    // def angularContainerExists = sh(script: "docker ps -a --filter 'name=${angularContainerName}' --format '{{.Names}}'", returnStatus: true) == 0
                    def containerExists = sh(script: "docker ps -a | grep -w ${containerName}", returnStatus: true) == 0
                    if (containerExists) {
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

        
                    // Créer et déployer la nouvelle image Docker pour l'application Angular
                    //def angularImageName = "angular:${buildNumber}"
                    //sh "docker run -d -p 82:4200 --name ${angularContainerName} ${angularImageName}"
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
                        def dockerRepoName = 'backup'

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
                script {
                    echo "Réussi"
                }
            }
        }
    }
}

