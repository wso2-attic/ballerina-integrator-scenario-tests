#!/bin/bash
# Copyright (c) 2019, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -o errexit
set -o pipefail
set -o nounset

trap propagate_cleanup_properties EXIT

setup_deployment_env() {
    local parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
    . ${parent_path}/common_utils.sh
    . ${parent_path}/deployment_utils.sh

    declare -g -A infra_config
    cat ${input_dir}/infrastructure.properties
    read_property_file "${input_dir}/infrastructure.properties" infra_config
    

    readonly docker_user=${infra_config["dockerhub_ballerina_scenarios_username"]}
    readonly docker_password=${infra_config["dockerhub_ballerina_scenarios_password"]}

    # Create a custom random namespace
    readonly cluster_namespace=$(generate_random_namespace)
    kubectl create namespace ${cluster_namespace}
    # Enforce the created namespace for future kubectl usages
    kubectl config set-context $(kubectl config current-context) --namespace=${cluster_namespace}

    local ballerina_version_type=${infra_config["BallerinaVersionType"]:-""}


    local ballerina_version_in_yaml="${infra_config["BallerinaVersion"]:-""}"
    if [ "${ballerina_version_in_yaml}" = "" ]; then
       echo "No information provided regarding the Ballerina version to use! Please add BallerinaVersion into deploymentConfig inputParameters."
       exit 2
    fi
    install_ballerina ${ballerina_version_in_yaml}


    local ballerina_version_cmd_output="$(${ballerina_home}/bin/ballerina version)"
    ballerina_version=$(sed "s:Ballerina ::g" <<< ${ballerina_version_cmd_output})

    echo "TestGroup=${infra_config["TestGroup"]}" >> ${output_dir}/deployment.properties
}

propagate_cleanup_properties() {
    # Store namespace to be cleaned up at the end
    echo "NamespacesToCleanup=${cluster_namespace}" >> ${output_dir}/infrastructure-cleanup.properties
}

if setup_deployment_env; then
    echo "Deployment set up successful"
else
    exit 1
fi
