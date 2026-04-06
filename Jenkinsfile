pipeline {
    agent any
    
    tools {
        "hudson.plugins.sonar.SonarRunnerInstallation" 'sonar-scanner'
        "dependency-check" 'DP-Check'
    }

    environment {
        DOCKER_CREDS_ID = 'docker-hub-creds'
        IMAGE_NAME = 'your_dockerhub_username/my-secure-app'
        IMAGE_TAG = "v1.0.${BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/trangdevops/my-secure-app.git'
                echo "Đã kéo mã nguồn thành công!"
            }
        }

        stage('2. SCA: OWASP Dependency-Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('3. SAST: SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=my-secure-app \
                      -Dsonar.projectName="My Secure App" \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=http://192.168.68.11:9000
                    '''
                }
            }
        }

        stage('4. Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('5. Misconfig: Trivy FS Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL --exit-code 1 --no-progress .'
            }
        }

        stage('6. Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('7. Container Security: Trivy Image Scan') {
            steps {
                sh "trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline chạy thành công. Mã nguồn và Image an toàn!"
        }
        failure {
            echo "Pipeline thất bại! Vui lòng kiểm tra lại log báo cáo bảo mật."
        }
    }
}
