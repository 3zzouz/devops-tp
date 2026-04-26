pipeline {
  agent any
  environment {
    DOCKER_IMAGE    = 'azizdh091/devops-tp-app'
    SONAR_TOKEN     = credentials('sonarqube-token')
    KUBECONFIG_PATH = credentials('kubeconfig')
  }
  stages {
    stage('Checkout')  { steps { checkout scm } }
    stage('Install')   { steps { dir('app') { sh 'npm ci' } } }

    stage('Unit Tests') {
      steps { dir('app') { sh 'npm test -- --coverage' } }
    }

    stage('SonarQube Analysis') {
      steps { withSonarQubeEnv('sonarqube') {
        dir('app') { sh 'sonar-scanner -Dsonar.token=${SONAR_TOKEN}' }
      }}
    }

    stage('Quality Gate') {
      steps { timeout(time:5, unit:'MINUTES') {
        waitForQualityGate abortPipeline: true
      }}
    }

    stage('Docker Build') {
      steps { sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ./app' }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          trivy image --exit-code 0 --severity HIGH,CRITICAL \
            --format table \
            --output trivy-report.txt \
            ${DOCKER_IMAGE}:${BUILD_NUMBER}
        '''
      }
      post { always { archiveArtifacts artifacts: 'trivy-report.txt' } }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(credentialsId:'dockerhub-creds',
          usernameVariable:'DOCKER_USER', passwordVariable:'DOCKER_PASS')]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'
          sh 'docker push ${DOCKER_IMAGE}:latest'
        }
      }
    }

    stage('Terraform Apply') {
      steps { dir('terraform') {
        sh 'terraform init && terraform apply -auto-approve'
      }}
    }

    stage('Ansible Deploy') {
      steps { sh 'ansible-playbook ansible/deploy.yaml' }
    }

    stage('Smoke Test') {
      steps {
        sh 'sleep 15'
        sh 'curl -f http://localhost:30080/health || exit 1'
      }
    }
  }

  post {
    success { echo 'Pipeline SUCCÈS – Application déployée !' }
    failure { echo 'Pipeline ÉCHEC – vérifier les logs ci-dessus.' }
  }
}
