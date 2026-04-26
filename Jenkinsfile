pipeline {
  agent any

  environment {
    DOCKER_IMAGE = '3zzouz/devops-tp-app'
    SONAR_TOKEN  = credentials('sonarqube-token')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Test') {
      agent {
        docker {
          image 'node:18-alpine'
          reuseNode true
        }
      }
      steps {
        dir('app') {
          sh 'npm ci'
          sh 'npm test'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonarqube') {
          dir('app') {
            sh 'sonar-scanner -Dsonar.token=${SONAR_TOKEN}'
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ./app'
      }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          trivy image \
            --exit-code 0 \
            --severity HIGH,CRITICAL \
            --format table \
            --output trivy-report.txt \
            ${DOCKER_IMAGE}:${BUILD_NUMBER}
        '''
      }
      post {
        always {
          archiveArtifacts 'trivy-report.txt'
        }
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'
          sh 'docker push ${DOCKER_IMAGE}:latest'
        }
      }
    }

  }

  post {
    success { echo '✅ Pipeline réussi !' }
    failure { echo '❌ Pipeline échoué — voir les logs.' }
  }
}
