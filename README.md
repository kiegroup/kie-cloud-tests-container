# kie-cloud-tests-container
Cloud (OpenShift) integration tests for KIE projects setup executed within a container image. Automation to run [kie-cloud-tests](https://github.com/kiegroup/kie-cloud-tests) in OpenShift CI.

Tests currently cover just Kie deployments deployed on OpenShift.

## Build command

From the repo dir run command

`docker build -t <kie-cloud-tests-image-tag> .`

## Run command from local

From the console run following command

`docker run -i --mount <directory with kubeconfig for ocp user> -t <kie-cloud-tests-image-tag> bash`
