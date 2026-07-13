pipeline {
  agent any

  environment {
    AWS_REGION = 'eu-west-3'
    AWS_ACCOUNT_ID = '915993062361'
    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    EC2_HOST = '35.180.190.123'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Test') {
      steps {
        script {
          def services = [
            'user-service',
            'device-service',
            'ingestion-service',
            'usage-service',
            'alert-service',
            'insight-service',
            'api-gateway'
          ]

          for (svc in services) {
            dir(svc) {
              echo "Building ${svc}..."
              sh 'chmod +x mvnw && ./mvnw -B -q -DskipTests package'
            }
          }
        }
      }
    }

    stage('Build & Push Docker Images') {
      steps {
        script {
          def services = [
            'user-service',
            'device-service',
            'ingestion-service',
            'usage-service',
            'alert-service',
            'insight-service',
            'api-gateway'
          ]

          withCredentials([usernamePassword(
            credentialsId: 'aws-credentials',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )]) {
            sh """
              aws ecr get-login-password --region ${AWS_REGION} \
              | docker login --username AWS --password-stdin ${ECR_REGISTRY}
            """

            for (svc in services) {
              def repo = "${ECR_REGISTRY}/home-energy-tracker/${svc}"
              sh """
                docker build -t ${repo}:${IMAGE_TAG} -t ${repo}:latest ${svc}
                docker push ${repo}:${IMAGE_TAG}
                docker push ${repo}:latest
              """
            }
          }
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent(credentials: ['ec2-ssh-key']) {
          sh """
            scp -o StrictHostKeyChecking=no docker-compose.prod.yml ubuntu@${EC2_HOST}:~/docker-compose.prod.yml
          """

          withCredentials([usernamePassword(
            credentialsId: 'aws-credentials',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )]) {
            sh """
              ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
                aws ecr get-login-password --region ${AWS_REGION} 2>/dev/null || \
                echo "${AWS_SECRET_ACCESS_KEY}" | docker login --username AWS --password-stdin ${ECR_REGISTRY}
              '
            """
          }

          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
              export IMAGE_TAG=${IMAGE_TAG}
              export ECR_REGISTRY=${ECR_REGISTRY}
              docker compose -f docker-compose.prod.yml pull
              docker compose -f docker-compose.prod.yml up -d
            '
          """
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline succeeded — build ${IMAGE_TAG} deployed to ${EC2_HOST}"
    }
    failure {
      echo "Pipeline failed — check the stage logs"
    }
    always {
      sh 'docker system prune -f || true'
    }
  }
}
