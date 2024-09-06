def REGISTRY_URL = 'cr.yandex'
def OWNER = 'crpui4gba34d6ts1hv80'
def REPO_NAME = 'simple-nginx-dev'
def IMAGE_NAME = 'nginx-devops'

def IMAGE_REGISTRY = "${REGISTRY_URL}/${OWNER}/${REPO_NAME}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"

def REGISTRY_CREDENTIALS = '3798a956-9159-49bc-894c-475852528da3'
def CLUSTER_CREDENTIALS = '3fc7f4f2-5fdd-49fd-98e2-6773a0d4fa0d'

def KUBERNETES_MANIFEST = 'kubernetes-manifest.yaml'
def STAGING_NAMESPACE = 'devops-tools'
def PRODUCTION_NAMESPACE = 'default'
def PULL_SECRET = "registry-${REGISTRY_CREDENTIALS}"

def DOCKER_HOST_VALUE = 'tcp://dind.devops-tools.svc.cluster.local:2375'

def DOCKER_POD = """
apiVersion: v1
kind: Pod
metadata:
  name: docker
  namespace: devops-tools
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
metadata:
  name: kubectl
  namespace: devops-tools
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
      agent { kubernetes label: 'docker', yaml: "${DOCKER_POD}" }
      stages {
        stage('Build Docker Image') {
          steps {
            container('docker') {
              sh "docker build -t ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]} ."
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
                echo ${REGISTRY_PASS} | docker login ${REGISTRY_URL} -u ${REGISTRY_USER} --password-stdin
                docker push ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]}
                docker tag ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]} ${IMAGE_BRANCH_TAG}
                docker push ${IMAGE_BRANCH_TAG}
                """
              }
            }
          }
        }
      }
    }
    stage('Deploy Master') {
      when { branch 'master' }
      agent { kubernetes label: 'kubectl', yaml: "${KUBECTL_POD}" }
      stages {
        stage('Deploy Image to Staging') {
          steps {
            container('kubectl') {
              withCredentials([
                file(
                  credentialsId: "${CLUSTER_CREDENTIALS}",
                  variable: 'KUBECONFIG'
                ),
                usernamePassword(
                  credentialsId: "${REGISTRY_CREDENTIALS}",
                  usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                )
              ]) {
                sh """
                kubectl \
                -n ${STAGING_NAMESPACE} \
                create secret docker-registry ${PULL_SECRET} \
                --docker-server=${REGISTRY_URL} \
                --docker-username=${REGISTRY_USER} \
                --docker-password=${REGISTRY_PASS} \
                --dry-run \
                -o yaml \
                | kubectl apply -f -

                sed \
                -e "s|{{NAMESPACE}}|${STAGING_NAMESPACE}|g" \
                -e "s|{{PULL_IMAGE}}|${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]}|g" \
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
          steps {
            container('kubectl') {
              withCredentials([
                file(
                  credentialsId: "${CLUSTER_CREDENTIALS}",
                  variable: 'KUBECONFIG'
                ),
                usernamePassword(
                  credentialsId: "${REGISTRY_CREDENTIALS}",
                  usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                )
              ]) {
                sh """
                kubectl \
                -n ${PRODUCTION_NAMESPACE} \
                create secret docker-registry ${PULL_SECRET} \
                --docker-server=${REGISTRY_URL} \
                --docker-username=${REGISTRY_USER} \
                --docker-password=${REGISTRY_PASS} \
                --dry-run \
                -o yaml \
                | kubectl apply -f -

                sed \
                -e "s|{{NAMESPACE}}|${PRODUCTION_NAMESPACE}|g" \
                -e "s|{{PULL_IMAGE}}|${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]}|g" \
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
