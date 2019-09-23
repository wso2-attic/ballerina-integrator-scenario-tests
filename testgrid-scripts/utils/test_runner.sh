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

run_test() {
    local scenario_name=$1;
    local outpur_directory=$2;

    mvn clean install -fae

    echo "Copying surefire-reports to ${outpur_directory}"
    mkdir -p ${outpur_directory}/scenarios/${scenario_name}
    find ./* -name "surefire-reports" -exec cp --parents -r {} ${outpur_directory}/scenarios/${scenario_name} \;
}

