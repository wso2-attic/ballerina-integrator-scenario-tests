// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/http;
import ballerina/kubernetes;
import ballerina/log;
import wso2/amazons3;

// Constants for error code and messages.

const string RESPOND_ERROR_MSG = "Error in responding to client.";
const string CLIENT_CREATION_ERROR_MSG = "Error while creating the AmazonS3 client.";
const string BUCKET_CREATION_ERROR_MSG = "Error while creating bucket on Amazon S3.";
const string BUCKET_DELETION_ERROR_MSG = "Error while deleting bucket from Amazon S3.";

// Read accessKey and secretKey from config files.
string accessKeyId = config:getAsString("ACCESS_KEY_ID");
string secretAccessKey = config:getAsString("SECRET_ACCESS_KEY");

// Create Amazons3 client configration with the above accesskey and secretKey values.
amazons3:ClientConfiguration amazonS3Config = {
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey,
    clientConfig: {
        http1Settings: {chunking: http:CHUNKING_NEVER}
    }
};

//Add `@kubernetes:Service` to a listner endpoint to expose the endpoint as Kubernetes Service.
@kubernetes:Service {
    //Service type is `NodePort`.
    serviceType: "NodePort"
}
//Add `@kubernetes:Ingress` to a listner endpoint to expose the endpoint as Kubernetes Ingress.
@kubernetes:Ingress {
    //Hostname of the service is `abc.com`.
    hostname: "s3.bi.wso2.com"
}
listener http:Listener awsS3EP = new http:Listener(9090);

//Add `@kubernetes:ConfigMap` annotation to a Ballerina service to mount configs to the container.
@kubernetes:ConfigMap {
    //Path to the ballerina.conf file.
    //If a releative path is provided, the path should be releative to where the `ballerina build` command is executed.
    conf: "./ballerina.conf"
}
//Add `@kubernetes:Deployment` annotation to a Ballerna service to generate Kuberenetes Deployment for a Ballerina module.
@kubernetes:Deployment {
    image: "ballerinaintegrator/s3_connector_test:v.1.0",
    name: "s3_connector_test",
    username: "ballerinaintegrator",
    password: "ballerinaintegrator",
    push: true,
    imagePullPolicy: "Always"
}
@http:ServiceConfig {
    basePath: "/amazons3"
}
service amazonS3Service on awsS3EP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{bucketName}"
    }
    // Function to create a new bucket.
    resource function createBucket(http:Caller caller, http:Request request, string bucketName) {
        // Create AmazonS3 client with the above amazonS3Config.
        amazons3:AmazonS3Client | error amazonS3Client = new (amazonS3Config);
        // Define new response.
        http:Response backendResponse = new ();

        if (amazonS3Client is amazons3:AmazonS3Client) {
            var response = amazonS3Client->createBucket(<@untainted>bucketName);
            if (response is error) {
                createAndSendErrorResponse(caller, <@untainted><string>response.detail()?.message,
                BUCKET_CREATION_ERROR_MSG);
            } else {
                // If there is no error, then bucket created successfully. Send the success response.
                backendResponse.setTextPayload(<@untainted>string `${bucketName} created on Amazon S3.`,
                contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            createAndSendErrorResponse(caller, <string>amazonS3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/{bucketName}"
    }
    // Function to delete bucket.
    resource function deleteBucket(http:Caller caller, http:Request request, string bucketName) {
        // Create AmazonS3 client with the above amazonS3Config.
        amazons3:AmazonS3Client | error amazonS3Client = new (amazonS3Config);
        // Define new response.
        http:Response backendResponse = new ();
        if (amazonS3Client is amazons3:AmazonS3Client) {
            var response = amazonS3Client->deleteBucket(<@untainted>bucketName);
            if (response is error) {
                createAndSendErrorResponse(caller, <@untainted><string>response.detail()?.message,
                BUCKET_DELETION_ERROR_MSG);
            } else {
                // If there is no error, then bucket deleted successfully. Send the success response.
                backendResponse.setTextPayload(<@untainted>string `${bucketName} deleted from Amazon S3.`,
                contentType = "text/plain");
                respondAndHandleError(caller, backendResponse, RESPOND_ERROR_MSG);
            }
        } else {
            createAndSendErrorResponse(caller, <string>amazonS3Client.detail()?.message, CLIENT_CREATION_ERROR_MSG);
        }
    }
}

// Function to create the error response.
function createAndSendErrorResponse(http:Caller caller, string errorMessage, string respondErrorMsg) {
    http:Response response = new;
    //Set 500 status code.
    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
    //Set the error message to the error response payload.
    response.setPayload(<string>errorMessage);
    respondAndHandleError(caller, response, respondErrorMsg);
}

// Function to send the response back to the client and handle the error.
function respondAndHandleError(http:Caller caller, http:Response response, string respondErrorMsg) {
    // Send response to the caller.
    var respond = caller->respond(response);
    if (respond is error) {
        log:printError(respondErrorMsg, err = respond);
    }
}
