#! /bin/bash
# Copyright (c) 2019, WSO2 Inc. (http://wso2.com) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

input_dir=$2
output_dir=$4

deployment_s3_parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
deployment_s3_grand_parent_path=$(dirname ${deployment_s3_parent_path})

. ${deployment_s3_grand_parent_path}/utils/usage.sh
. ${deployment_s3_grand_parent_path}/utils/setup_deployment_env.sh

ballerina_integrator_aws_s3_access_key=${infra_config["ballerina_integrator_aws_s3_access_key"]}
ballerina_integrator_aws_s3_secret_key=${infra_config["ballerina_integrator_aws_s3_secret_key"]}

setup_deployment(){
    download_s3
    build_bal_service
    wait_for_pod_readiness
    write_properties_to_data_bucket
}

#Download S3 connector
download_s3(){
git clone https://github.com/wso2-ballerina/module-amazons3.git
cd module-amazons3
${ballerina_home}/bin/ballerina build -c --skip-tests amazons3
cd ..
echo "=== S3 setup successfully  ==="
}

#Copy ballerina service to s3
build_bal_service(){
cp -r connectors/s3-tests/src/test/resources/s3test ./module-amazons3/src
cd module-amazons3
touch ballerina.conf
chmod -R 766 ballerina.conf

echo "ACCESS_KEY_ID="\"$ballerina_integrator_aws_s3_access_key\" >> ./ballerina.conf
echo "SECRET_ACCESS_KEY="\"$ballerina_integrator_aws_s3_secret_key\" >> ./ballerina.conf

${ballerina_home}/bin/ballerina build s3test --b7a.config.file=./ballerina.conf

echo "=== Ballerina service built successfully ==="

# Run generated docker
kubectl apply -f ./target/kubernetes/s3test --namespace=${cluster_namespace}
}

write_properties_to_data_bucket() {
    local external_ip=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    local node_port=$(kubectl get svc awss3ep-svc -o=jsonpath='{.spec.ports[0].nodePort}')
    declare -A deployment_props
    deployment_props["ExternalIP"]=${external_ip}
    deployment_props["NodePort"]=${node_port}
    deployment_props["namespace"]=${cluster_namespace}
    write_to_properties_file ${output_dir}/deployment.properties deployment_props
    echo "ExternalIP: ${external_ip}"
    echo "NodePort: ${node_port}"

}

setup_deployment

