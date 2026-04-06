pipeline {
    agent any
    
    tools {
        // Tên công cụ phải khớp chính xác với tên bạn đã đặt trong Manage Jenkins -> Tools
        sonarScanner 'sonar-scanner'
        dependencyCheck 'DP-Check'
    }

    environment {
        // Định nghĩa các biến môi trường
        DOCKER_CREDS_ID = 'docker-hub-creds'
        IMAGE_NAME = 'your_dockerhub_username/my-secure-app'
        IMAGE_TAG = "v1.0.${BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                // Kéo mã nguồn từ nhánh main của GitHub (Thay bằng URL repo của bạn)
                git branch: 'main', url: 'https://github.com/your-org/your-repo.git'
                echo "Đã kéo mã nguồn thành công!"
            }
        }

        stage('2. SCA: OWASP Dependency-Check') {
            steps {
                // Quét lỗ hổng trong các thư viện (ví dụ: package.json, pom.xml)
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                // Xuất báo cáo lên giao diện Jenkins
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('3. SAST: SonarQube Analysis') {
            steps {
                // Tên 'SonarQube-Server' phải khớp với tên đã cấu hình trong Manage Jenkins -> System
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=my-secure-app \
                      -Dsonar.projectName="My Secure App" \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=http://192.168.56.11:9000
                    '''
                }
            }
        }

        stage('4. Quality Gate') {
            steps {
                // Dừng Pipeline tối đa 5 phút để chờ SonarQube trả kết quả phân tích về
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('5. Misconfig: Trivy FS Scan') {
            steps {
                // Quét mã nguồn và Dockerfile tìm cấu hình sai, bỏ qua lỗi nhẹ, fail nếu có CRITICAL
                sh 'trivy fs --severity HIGH,CRITICAL --exit-code 1 --no-progress .'
            }
        }

        stage('6. Docker Build & Push') {
            steps {
                // Dùng credentials của Docker Hub để login và push image
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} # Dọn rác trên node CI
                    '''
                }
            }
        }

        stage('7. Container Security: Trivy Image Scan') {
            steps {
                // Quét Image vừa được đẩy lên registry
                sh "trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            // Dọn dẹp thư mục làm việc sau khi Pipeline chạy xong để giải phóng ổ cứng
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
