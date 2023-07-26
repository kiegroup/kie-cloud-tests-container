#!/bin/bash
set -o pipefail

OLM_CHANNEL=${OLM_CHANNEL:-stable}

if [[ -z "${VERSION}" ]]; then
  echo "'VERSION' ENV variable is not found - extract it from the cluster (from the '$OLM_CHANNEL' channel)"
  VERSION=$(oc get packagemanifests businessautomation-operator -o jsonpath="{.status.channels[?(@.name=='${OLM_CHANNEL}')].currentCSVDesc.version}")
  ## get rid of the build suffix for operator respins
  VERSION=${VERSION%-?*}
fi

REPO=https://github.com/jakubschwan/kie-cloud-tests.git
FAILSAFE_REPORTS_DIR="kie-cloud-tests/test-cloud/test-cloud-remote/target/failsafe-reports" 
RESULTS_DIR="${TEST_COLLECT_BASE_DIR:=/data/results}"

OCP_URL_SUFFIX=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
OCP_API_URL=$(oc whoami --show-server)
OCP_API_USER=$(oc whoami)
OCP_API_TOKEN=$(oc whoami -t)

IMAGE_STREAM_FILE=/opt/imageStream.yaml
NEXUS_IMAGE_STREAM_FILE=/opt/nexusImageStream.yaml

KIE_VERSION=7.67.x
KIE_IMAGE_TAG=rhpam-rhel8-operator:${VERSION}

fail() {
  echo "$@" 1>&2
  exit 1
}

clone_testsuite() {
  echo "Clonning the test suite from $REPO:7.67.x-containerized"
  git clone -q --single-branch -c http.sslVerify=false --branch 7.67.x-containerized ${REPO}
}

build_test() {
    echo "Building test framework"
    mvn clean install -DskipTests --batch-mode | tee -a kie-cloud-test_v7.67.x_build.log

    echo "Build completed"
}

run_test() {
  echo "Executing test-cloud-remote"
  mvn clean install --batch-mode -Popenshift-operator -Psmoke -Pinterop -Ddefault.domain.suffix=.${OCP_URL_SUFFIX} -Dgit.provider=Gogs -Dkie.artifact.version=${KIE_VERSION} -Dmaven.test.failure.ignore=true -Dopenshift.master.url=${OCP_API_URL} -Dopenshift.admin.token=${OCP_API_TOKEN} -Dopenshift.admin.username=${OCP_API_USER} -Dopenshift.token=${OCP_API_TOKEN} -Dopenshift.username=${OCP_API_USER} -Dopenshift.namespace.prefix=rhba-interop -Dtemplate.project=jbpm -Dkie.operator.image.tag=${KIE_IMAGE_TAG} -Dkie.image.streams=${IMAGE_STREAM_FILE} -Dnexus.mirror.image.stream=${NEXUS_IMAGE_STREAM_FILE} > kie-cloud-test_v7.67.x_run.log -Dcloud.properties.location=/opt/private.properties
   
  echo "Tests completed"
}

remove_properties_from_test_reports() {
  echo "Removing properties from test reports"
  for file in "${FAILSAFE_REPORTS_DIR}/*"
  do
    sed -i  "/\<property\>/d" $file
  done
}

copy_logs_and_reports_to_result_dir() {
  echo "Copy the build log and test log with results to ${RESULTS_DIR}"
  cp kie-cloud-tests/kie-cloud-test_v7.67.x_build.log "${RESULTS_DIR}"
  cp kie-cloud-tests/test-cloud/test-cloud-remote/kie-cloud-test_v7.67.x_run.log "${RESULTS_DIR}"
  cp -r "${FAILSAFE_REPORTS_DIR}/*" "${RESULTS_DIR}"
  echo "Copy of logs and results is completed"
}

if [ -z "$VERSION" ]; then
  fail "[ERROR] VERSION variable is not set."
fi

clone_testsuite

cd kie-cloud-tests
build_test

cd test-cloud/test-cloud-remote
run_test
remove_properties_from_test_reports

cd ~
copy_logs_and_reports_to_result_dir