def REGISTRY_URL = 'cr.yandex'
def OWNER = 'crpui4gba34d6ts1hv80'
def REPO_NAME = 'simple-nginx-dev'
def IMAGE_NAME = 'nginx-devops'

def IMAGE_REGISTRY = "${REGISTRY_URL}/${OWNER}/${REPO_NAME}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"

def REGISTRY_CREDENTIALS = 'atlantis'
def CLUSTER_CREDENTIALS = 'kubeconfig'

def KUBERNETES_MANIFEST = 'kubernetes-manifest.yaml'
def STAGING_NAMESPACE = 'devops-tools'
def PRODUCTION_NAMESPACE = 'devops-tools'
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
