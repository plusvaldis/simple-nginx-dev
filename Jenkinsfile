def REGISTRY_URL = 'https://cr.yandex/'
def REGISTRY_NAME = 'cr.yandex'
def OWNER = 'crpfvupvff8lra5lqkar'
def REPO_NAME = 'simple-nginx-dev'
def IMAGE_NAME = 'simple-nginx-dev'

def IMAGE_REGISTRY = "${REGISTRY_URL}/${OWNER}/${REPO_NAME}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.TAG_NAME}"

def REGISTRY_CREDENTIALS = 'a0e287e8-42d4-4786-bc8f-88cb475dfc8d'
def CLUSTER_CREDENTIALS = 'e35d50c7-0dfa-4fe3-9c8b-990531d6a8f6'

def KUBERNETES_MANIFEST = 'kubernetes-manifest.yaml'
def STAGING_NAMESPACE = 'devops-tools'
def PRODUCTION_NAMESPACE = 'prod'
def PULL_SECRET = "registry-${REGISTRY_CREDENTIALS}"

def DOCKER_HOST_VALUE = 'tcp://dind.devops-tools.svc.cluster.local:2375'

def DOCKER_POD = """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:19.03.6
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: ${DOCKER_HOST_VALUE}
"""

def KUBECTL_POD = """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: lachlanevenson/k8s-kubectl:v1.15.9
    command:
    - cat
    tty: true
"""


pipeline {
  agent any
  stages {
    stage('Run Docker') {
      agent { kubernetes inheritFrom: 'docker', yaml: "${DOCKER_POD}" }
      stages {
        stage('Build Docker Image') {
          steps {
            container('docker') {
              sh "docker build -t ${IMAGE_BRANCH_TAG}.${env.TAG_NAME} ."
            }
          }
        }
        stage('Push Image to Registry') {
          steps {
            container('docker') {
              withCredentials([
                usernamePassword(
                  credentialsId: "${REGISTRY_CREDENTIALS}",
                  usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                )
              ]) {
                sh """
                echo ${REGISTRY_PASS} | docker login ${REGISTRY_NAME} -u ${REGISTRY_USER} --password-stdin
                docker tag ${env.TAG_NAME}
                docker push ${IMAGE_BRANCH_TAG}
                """
              }
            }
          }
        }
      }
    }
    stage('Deploy Master') {
      when { expression { sh([returnStdout: true, script: 'echo $TAG_NAME | tr -d \'\n\'']) } }
      environment {
        EXAMPLE_CREDS = credentials("${REGISTRY_CREDENTIALS}")
      }
      agent { kubernetes inheritFrom: 'kubectl', yaml: "${KUBECTL_POD}" }
      stages {
        stage('Deploy Image to Staging') {
          steps {
            container('kubectl') {
              withCredentials([
                file(
                  credentialsId: "${CLUSTER_CREDENTIALS}",
                  variable: 'KUBECONFIG'
                )
              ]) {
                sh """
                kubectl \
                -n ${STAGING_NAMESPACE} \
                create secret docker-registry ${PULL_SECRET} \
                --docker-server=${REGISTRY_URL} \
                --docker-username=${EXAMPLE_CREDS_USR} \
                --docker-password=${EXAMPLE_CREDS_PSW} \
                --dry-run \
                -o yaml \
                | kubectl apply -f -

                sed \
                -e "s|{{NAMESPACE}}|${STAGING_NAMESPACE}|g" \
                -e "s|{{PULL_IMAGE}}|${IMAGE_BRANCH_TAG}|g" \
                -e "s|{{PULL_SECRET}}|${PULL_SECRET}|g" \
                ${KUBERNETES_MANIFEST} \
                | kubectl apply -f -
                """
              }
            }
          }
        }
        stage('Manual Review') {
          agent none
          steps {
            timeout(time:2, unit:'DAYS') {
              input message: 'Deploy image to production?'
            }
          }
        }
        stage('Deploy Image to Production') {
          environment {
          EXAMPLE_CREDS = credentials("${REGISTRY_CREDENTIALS}")
          }
          steps {
            container('kubectl') {
              withCredentials([
                file(
                  credentialsId: "${CLUSTER_CREDENTIALS}",
                  variable: 'KUBECONFIG'
                )
              ]) {
                sh """
                kubectl \
                -n ${PRODUCTION_NAMESPACE} \
                create secret docker-registry ${PULL_SECRET} \
                --docker-server=${REGISTRY_URL} \
                --docker-username=${EXAMPLE_CREDS_USR} \
                --docker-password=${EXAMPLE_CREDS_PSW} \
                --dry-run \
                -o yaml \
                | kubectl apply -f -

                sed \
                -e "s|{{NAMESPACE}}|${PRODUCTION_NAMESPACE}|g" \
                -e "s|{{PULL_IMAGE}}|${IMAGE_BRANCH_TAG}|g" \
                -e "s|{{PULL_SECRET}}|${PULL_SECRET}|g" \
                ${KUBERNETES_MANIFEST} \
                | kubectl apply -f -
                """
              }
            }
          }
        }
      }
    }
  }
}
