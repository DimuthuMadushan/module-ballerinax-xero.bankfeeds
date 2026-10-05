// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/os;
import ballerina/test;
import ballerina/time;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer ? "https://api.xero.com/bankfeeds.xro/1.0" : "http://localhost:9090";

final string token = isLiveServer ? os:getEnv("XERO_ACCESS_TOKEN") : "test_token";
final string tenantId = isLiveServer ? os:getEnv("XERO_TENANT_ID") : "8f04f4b1-6ff4-4b1d-bb47-73f1f3d32d4a";
final string feedConnectionId = isLiveServer ? os:getEnv("XERO_FEED_CONNECTION_ID") : MOCK_FEED_CONNECTION_ID;
final string statementId = isLiveServer ? os:getEnv("XERO_STATEMENT_ID") : MOCK_STATEMENT_ID;

final Client xero = check new ({
        auth: {token},
        // The mock is plain HTTP; HTTP/1.1 avoids the h2c upgrade on POST requests.
        httpVersion: isLiveServer ? http:HTTP_2_0 : http:HTTP_1_1
    },
    serviceUrl
);

// Returns a value unique to this test run, so live reruns never collide with an earlier fixture.
isolated function runSuffix() returns string => time:utcNow()[0].toString();

// Formats a UTC time as an ISO-8601 date, YYYY-MM-DD.
isolated function isoDate(time:Utc utc) returns string => time:utcToString(utc).substring(0, 10);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetFeedConnections() returns error? {
    FeedConnections response = check xero->getFeedConnections({xeroTenantId: tenantId}, page = 1, pageSize = 10);
    test:assertTrue(response.pagination !is (), "Expected pagination details");
    FeedConnection[] items = response.items ?: [];
    test:assertTrue(items.length() > 0, "Expected at least one feed connection");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetFeedConnection() returns error? {
    FeedConnection response = check xero->getFeedConnection(feedConnectionId, {xeroTenantId: tenantId});
    test:assertEquals(response.id, feedConnectionId);
    test:assertTrue(response.accountToken !is (), "Expected an account token");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testCreateFeedConnections() returns error? {
    string suffix = runSuffix();
    FeedConnections response = check xero->createFeedConnections({xeroTenantId: tenantId}, {
        items: [
            {
                accountToken: "ballerina-create-" + suffix,
                accountNumber: "1234" + suffix,
                accountName: "Ballerina Test Account",
                accountType: "BANK",
                currency: "GBP"
            }
        ]
    });
    FeedConnection[] items = response.items ?: [];
    test:assertEquals(items.length(), 1);
    test:assertEquals(items[0].status, "PENDING");
    test:assertTrue(items[0].id !is (), "Expected the new feed connection's ID");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testDeleteFeedConnections() returns error? {
    string suffix = runSuffix();
    FeedConnections created = check xero->createFeedConnections({xeroTenantId: tenantId}, {
        items: [
            {
                accountToken: "ballerina-delete-" + suffix,
                accountNumber: "5678" + suffix,
                accountName: "Ballerina Delete Account",
                accountType: "BANK",
                currency: "GBP"
            }
        ]
    });
    FeedConnection[] createdItems = created.items ?: [];
    test:assertEquals(createdItems.length(), 1);
    string? createdId = createdItems[0].id;
    if createdId is () {
        return error("The create request did not return a feed connection ID");
    }

    FeedConnections response = check xero->deleteFeedConnections({xeroTenantId: tenantId}, {
        items: [{id: createdId}]
    });
    FeedConnection[] items = response.items ?: [];
    test:assertEquals(items.length(), 1);
    test:assertEquals(items[0].id, createdId);
    test:assertEquals(items[0].status, "PENDING");
}

// Mock only: live, Xero processes a deletion asynchronously, so a second request can still be accepted.
@test:Config {
    groups: ["mock_tests"]
}
function testDeleteFeedConnectionsTwiceIsRejected() returns error? {
    FeedConnections created = check xero->createFeedConnections({xeroTenantId: tenantId}, {
        items: [{accountToken: "ballerina-twice", accountNumber: "99887766", accountType: "BANK", currency: "GBP"}]
    });
    FeedConnection[] createdItems = created.items ?: [];
    test:assertEquals(createdItems.length(), 1);
    string? createdId = createdItems[0].id;
    if createdId is () {
        return error("The create request did not return a feed connection ID");
    }
    _ = check xero->deleteFeedConnections({xeroTenantId: tenantId}, {items: [{id: createdId}]});

    FeedConnections response = check xero->deleteFeedConnections({xeroTenantId: tenantId}, {
        items: [{id: createdId}]
    });
    FeedConnection[] items = response.items ?: [];
    test:assertEquals(items.length(), 1);
    test:assertEquals(items[0].status, "REJECTED");
    test:assertEquals(items[0]?.'error?.'type, "feed-not-found-or-already-deleted");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetStatements() returns error? {
    Statements response = check xero->getStatements({xeroTenantId: tenantId}, page = 1, pageSize = 10);
    test:assertTrue(response.pagination !is (), "Expected pagination details");
    Statement[] items = response.items ?: [];
    test:assertTrue(items.length() > 0, "Expected at least one statement");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetStatement() returns error? {
    Statement response = check xero->getStatement(statementId, {xeroTenantId: tenantId});
    test:assertEquals(response.id, statementId);
    test:assertTrue(response.startBalance !is (), "Expected a start balance");
    test:assertTrue(response.endBalance !is (), "Expected an end balance");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testCreateStatements() returns error? {
    // Xero rejects a start date older than one year, so the statement covers yesterday and today.
    time:Utc now = time:utcNow();
    string today = isoDate(now);
    string yesterday = isoDate(time:utcAddSeconds(now, -86400));
    Statements response = check xero->createStatements({xeroTenantId: tenantId, idempotencyKey: "ballerina-" + runSuffix()}, {
        items: [
            {
                feedConnectionId,
                startDate: yesterday,
                endDate: today,
                startBalance: {amount: 250.00, creditDebitIndicator: "CREDIT"},
                endBalance: {amount: 225.50, creditDebitIndicator: "CREDIT"},
                statementLines: [
                    {
                        postedDate: today,
                        description: "Card purchase",
                        amount: 24.50,
                        creditDebitIndicator: "DEBIT",
                        transactionId: "ballerina-txn-" + runSuffix(),
                        payeeName: "Contoso Coffee"
                    }
                ]
            }
        ]
    });
    Statement[] items = response.items ?: [];
    test:assertEquals(items.length(), 1);
    test:assertEquals(items[0].feedConnectionId, feedConnectionId);
    test:assertEquals(items[0].status, "PENDING");
    test:assertTrue(items[0].id !is (), "Expected the new statement's ID");
}

@test:Config {
    groups: ["mock_tests"]
}
function testCreateStatementsRejectsUnbalancedStatement() {
    Statements|error response = xero->createStatements({xeroTenantId: tenantId}, {
        items: [
            {
                feedConnectionId,
                startDate: "2026-09-01",
                endDate: "2026-09-02",
                startBalance: {amount: 100.00, creditDebitIndicator: "CREDIT"},
                endBalance: {amount: 90.00, creditDebitIndicator: "CREDIT"},
                statementLines: [{postedDate: "2026-09-02", description: "Fee", amount: 5.00, creditDebitIndicator: "DEBIT"}]
            }
        ]
    });
    if response !is http:ClientRequestError {
        test:assertFail("Expected a 422 client request error for an unbalanced statement");
    }
    test:assertEquals(response.detail().statusCode, 422);
}
