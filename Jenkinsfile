pipeline {
  agent any

  environment {
    AWS_REGION = 'eu-west-3'
    AWS_ACCOUNT_ID = '915993062361'
    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    EC2_HOST = '15.224.158.23'
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
              retry(3) {
                sh '''
                  if [ -x ./mvnw ] && [ -f ./.mvn/wrapper/maven-wrapper.properties ]; then
                    chmod +x mvnw
                    ./mvnw -B -q -DskipTests package
                  else
                    mvn -B -q -DskipTests package
                  fi
                '''
              }
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
              retry(3) {
                sh """
                  docker build -t ${repo}:${IMAGE_TAG} -t ${repo}:latest ${svc}
                """
              }
              retry(3) {
                sh """
                  docker push ${repo}:${IMAGE_TAG}
                  docker push ${repo}:latest
                """
              }
            }
          }
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: 'ec2-ssh-key',
          keyFileVariable: 'SSH_KEY',
          usernameVariable: 'SSH_USER'
        )]) {
          sh """
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ${SSH_KEY} ${SSH_USER}@${EC2_HOST} 'echo SSH_OK'
            scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ${SSH_KEY} docker-compose.prod.yml ${SSH_USER}@${EC2_HOST}:~/docker-compose.prod.yml
          """

          withCredentials([usernamePassword(
            credentialsId: 'aws-credentials',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )]) {
            sh """
              ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ${SSH_KEY} ${SSH_USER}@${EC2_HOST} '
                export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
                export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
                export AWS_DEFAULT_REGION="${AWS_REGION}"
                if ! command -v aws >/dev/null 2>&1; then
                  sudo apt-get update -y
                  sudo apt-get install -y awscli
                fi
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
              '
            """
          }

          sh """
            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_USER}@${EC2_HOST} '
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
      echo "Pipeline failed — check the stage logs above"
    }
    always {
      echo 'Pipeline finished'
      echo 'Deployment step completed'
    }
  }
}
