pipeline {
    agent any
    
    environment {
        // Registry configuration - update these for your Gitea instance
        REGISTRY_URL = 'gitea.example.com'  // Replace with your Gitea hostname
        REGISTRY_NAMESPACE = 'your-username'  // Replace with your Gitea username
        IMAGE_NAME = 'django-crm'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Jenkins credential IDs (configure these in Jenkins)
        REGISTRY_CREDENTIALS = 'gitea-registry-creds'
        
        // Full image reference
        FULL_IMAGE_NAME = "${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build Info') {
            steps {
                script {
                    echo "Building ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Git Commit: ${env.GIT_COMMIT}"
                    echo "Git Branch: ${env.GIT_BRANCH}"
                }
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    def image = docker.build("${FULL_IMAGE_NAME}:${IMAGE_TAG}")
                    
                    // Also tag as 'latest' if on main branch
                    if (env.GIT_BRANCH == 'origin/main' || env.GIT_BRANCH == 'main') {
                        image.tag('latest')
                    }
                }
            }
        }
        
        stage('Test Container') {
            steps {
                script {
                    echo 'Testing container startup...'
                    
                    // Start a test instance to verify it starts correctly
                    sh """
                        docker run --rm -d --name crm-test-${BUILD_NUMBER} \
                            -e MYSQL_HOST=localhost \
                            -e MYSQL_DATABASE=test_db \
                            -e MYSQL_USER=test \
                            -e MYSQL_PASSWORD=test \
                            ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
                            sh -c 'python manage.py check --deploy; sleep 10'
                    """
                    
                    // Wait a moment then check if it's still running
                    sh "sleep 5"
                    sh "docker ps | grep crm-test-${BUILD_NUMBER}"
                    
                    // Cleanup test container
                    sh "docker stop crm-test-${BUILD_NUMBER} || true"
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master' 
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo 'Pushing to container registry...'
                    
                    docker.withRegistry("https://${REGISTRY_URL}", REGISTRY_CREDENTIALS) {
                        def image = docker.image("${FULL_IMAGE_NAME}:${IMAGE_TAG}")
                        
                        // Push tagged version
                        image.push("${IMAGE_TAG}")
                        
                        // Push latest if on main branch
                        if (env.GIT_BRANCH == 'origin/main' || env.GIT_BRANCH == 'main') {
                            image.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Update Deployment') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Deployment update would go here...'
                    echo "New image available: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                    
                    // Future: trigger deployment update
                    // e.g., update docker-compose.yml with new image tag
                    // or trigger Kubernetes deployment update
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            
            // Clean up test containers
            sh "docker ps -aq --filter name=crm-test-${BUILD_NUMBER} | xargs -r docker rm -f || true"
            
            // Clean up intermediate images
            sh "docker image prune -f || true"
        }
        
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
        }
        
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
