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

package org.wso2.integration.ballerina.test;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.BeforeTest;
import org.testng.annotations.Test;

import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Properties;

import static io.restassured.RestAssured.given;

public class S3Test {
    private static final String INPUTS_LOCATION = System.getenv("input_dir");
    private static String externalip;
    private static String nodeport;
    private static String namespace;

    static void initParams() throws Exception {
        InputStream input = new FileInputStream(INPUTS_LOCATION + "/deployment.properties");
        Properties props = new Properties();
        props.load(input);
        externalip = props.getProperty("ExternalIP");
        nodeport = props.getProperty("NodePort");
        namespace = props.getProperty("namespace");
    }

    @BeforeTest
    public void init() throws Exception {
        try {
            initParams();
            RestAssured.baseURI = "http://" + externalip + ":" + nodeport + "/amazons3/";
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testCreatebucket() {
        Response response = given().
                when().
                post("http://" + externalip + ":" + nodeport + "/amazons3/ballerina-integrator-bucket25");
        Assert.assertTrue(response.statusCode() == 200);
    }

    @Test(dependsOnMethods = { "testCreatebucket" })
    public void testDeletebucket() {
        Response response = given().
                when().
                delete("http://" + externalip + ":" + nodeport + "/amazons3/ballerina-integrator-bucket25");
        Assert.assertTrue(response.statusCode() == 200);
    }
}
