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

listener http:Listener ep0 = new (9090);

// The feed connections and statements the mock currently holds, keyed by ID.
type MockStore record {|
    map<FeedConnection> feedConnections;
    map<Statement> statements;
    int nextId;
|};

isolated MockStore store = seedStore();

const MOCK_FEED_CONNECTION_ID = "6a4b9ff5-3a5f-4321-936b-4796163550f6";
const MOCK_STATEMENT_ID = "97aca24a-dd10-4cda-98c7-1084a048257b";

service / on ep0 {
    # Searches for feed connections
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + page - Page number which specifies the set of records to retrieve. By default the number of the records per set is 10. Example - https://api.xero.com/bankfeeds.xro/1.0/FeedConnections?page=2 to get the second set of the records. When page value is not a number or a negative number, by default, the first set of records is returned
    # + pageSize - Page size which specifies how many records per page will be returned (default 10). Example - https://api.xero.com/bankfeeds.xro/1.0/FeedConnections?pageSize=100 to specify page size of 100
    # + return - returns can be any of following types
    # http:Accepted (A page of feed connections, with pagination details)
    # http:BadRequest (validation error response)
    resource function get FeedConnections(@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId, int? page, int? pageSize) returns FeedConnectionsAccepted|http:BadRequest {
        FeedConnection[] all;
        lock {
            all = store.feedConnections.toArray().cloneReadOnly();
        }
        [int, int, int, int] [first, last, currentPage, size] = pageBounds(all.length(), page, pageSize);
        FeedConnections result = {
            pagination: {page: currentPage, pageSize: size, pageCount: pageCount(all.length(), size), itemCount: last - first},
            items: all.slice(first, last)
        };
        return <FeedConnectionsAccepted>{body: result};
    }

    # Retrieves a single feed connection by its unique ID
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + id - Unique identifier for retrieving single object
    # + return - returns can be any of following types
    # http:Ok (The feed connection matching the given ID)
    # http:BadRequest (bad input parameter)
    resource function get FeedConnections/[string id](@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId) returns FeedConnection|http:BadRequest {
        FeedConnection? found;
        lock {
            found = store.feedConnections[id].cloneReadOnly();
        }
        if found is () {
            return <http:BadRequest>{
                body: <Error>{
                    'type: "bank-feed-not-found",
                    title: "Bank Feed Not Found",
                    status: 400,
                    detail: string `No feed connection exists with the ID '${id}'.`
                }
            };
        }
        return found;
    }

    # Retrieves all statements
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + page - Page number which specifies the set of records to retrieve. By default the number of the records per set is 10. Example - https://api.xero.com/bankfeeds.xro/1.0/Statements?page=2 to get the second set of the records. When page value is not a number or a negative number, by default, the first set of records is returned
    # + pageSize - Page size which specifies how many records per page will be returned (default 10). Example - https://api.xero.com/bankfeeds.xro/1.0/Statements?pageSize=100 to specify page size of 100
    # + xeroApplicationId - Xero identifier of the application making the request
    # + xeroUserId - Xero identifier of the user on whose behalf the request is made
    # + return - returns can be any of following types
    # http:Ok (A page of statements, with pagination details)
    # http:BadRequest (bad input parameter)
    resource function get Statements(@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId, int:Signed32? page, int:Signed32? pageSize, @http:Header {name: "Xero-Application-Id"} string? xeroApplicationId = "00000000-0000-0000-0000-0000000010000", @http:Header {name: "Xero-User-Id"} string? xeroUserId = "00000000-0000-0000-0000-0000030000000") returns Statements|StatementsBadRequest {
        Statement[] all;
        lock {
            all = store.statements.toArray().cloneReadOnly();
        }
        [int, int, int, int] [first, last, currentPage, size] = pageBounds(all.length(), page, pageSize);
        // The list view omits the statement lines, as the real API does.
        Statement[] summaries = from Statement s in all.slice(first, last)
            select {
                id: s.id,
                feedConnectionId: s.feedConnectionId,
                status: s.status,
                startDate: s.startDate,
                endDate: s.endDate,
                startBalance: s.startBalance,
                endBalance: s.endBalance,
                statementLineCount: s.statementLineCount
            };
        Statements result = {
            pagination: {page: currentPage, pageSize: size, pageCount: pageCount(all.length(), size), itemCount: summaries.length()},
            items: summaries
        };
        return result;
    }

    # Retrieves a single statement by its unique ID
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + statementId - statement id for single object
    # + return - returns can be any of following types
    # http:Ok (The statement matching the given ID)
    # http:NotFound (Statement not found)
    resource function get Statements/[string statementId](@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId) returns Statement|http:NotFound {
        Statement? found;
        lock {
            found = store.statements[statementId].cloneReadOnly();
        }
        if found is () {
            return <http:NotFound>{
                body: <Error>{
                    'type: "statement-not-found",
                    title: "Statement Not Found",
                    status: 404,
                    detail: string `No statement exists with the ID '${statementId}'.`
                }
            };
        }
        return found;
    }

    # Creates one or more new feed connections
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Feed Connection(s) array object in the body
    # + return - returns can be any of following types
    # http:Accepted (The submitted feed connections, each with its status)
    # http:BadRequest (failed to create new feed connection(s)response)
    resource function post FeedConnections(@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload FeedConnections payload) returns FeedConnectionsAccepted|FeedConnectionsBadRequest {
        FeedConnection[] submitted = payload.items ?: [];
        FeedConnection[] results = [];
        lock {
            FeedConnection[] acc = [];
            foreach FeedConnection item in submitted.clone() {
                string? token = item.accountToken;
                if token is () || (item.accountNumber is () && item.accountId is ()) {
                    acc.push({
                        accountToken: token,
                        status: "REJECTED",
                        'error: {
                            'type: "invalid-request",
                            title: "Invalid Request",
                            status: 400,
                            detail: "AccountToken and one of AccountNumber or AccountId are required."
                        }
                    });
                    continue;
                }
                string id = nextMockId(store, "2a19d46c-2a92-4e50-9401-");
                FeedConnection created = item.clone();
                created.id = id;
                created.accountId = item.accountId ?: nextMockId(store, "aefbf6be-4285-4ca5-bf39-");
                created.status = "PENDING";
                store.feedConnections[id] = created;
                acc.push({id, accountToken: token, status: "PENDING"});
            }
            results = acc.cloneReadOnly();
        }
        return <FeedConnectionsAccepted>{body: {items: results}};
    }

    # Deletes one or more existing feed connections
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Feed Connections array object in the body
    # + return - returns can be any of following types
    # http:Accepted (The feed connections submitted for deletion, each with its status)
    # http:BadRequest (bad input parameter)
    resource function post FeedConnections/DeleteRequests(@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload FeedConnections payload) returns FeedConnectionsAccepted|http:BadRequest {
        FeedConnection[] submitted = payload.items ?: [];
        FeedConnection[] results = [];
        lock {
            FeedConnection[] acc = [];
            foreach FeedConnection item in submitted.clone() {
                string? id = item.id;
                if id is string && store.feedConnections.hasKey(id) {
                    _ = store.feedConnections.remove(id);
                    acc.push({id, status: "PENDING"});
                } else {
                    acc.push({
                        id,
                        accountToken: item.accountToken,
                        status: "REJECTED",
                        'error: {
                            'type: "feed-not-found-or-already-deleted",
                            title: "Feed not found or already deleted",
                            detail: "The feed connection does not exist or has already been deleted."
                        }
                    });
                }
            }
            results = acc.cloneReadOnly();
        }
        return <FeedConnectionsAccepted>{body: {items: results}};
    }

    # Creates one or more new statements
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Statements array of objects in the body
    # + return - returns can be any of following types
    # http:Accepted (The submitted statements, each with its status)
    # http:BadRequest (Statement failed validation)
    # http:Forbidden (Invalid application or feed connection)
    # http:Conflict (Duplicate statement received)
    # http:PayloadTooLarge (Statement exceeds size limit)
    # http:UnprocessableEntity (Unprocessable Entity)
    # http:InternalServerError (Intermittent Xero Error)
    resource function post Statements(@http:Header {name: "Xero-Tenant-Id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Statements payload) returns StatementsAccepted|StatementsBadRequest|ErrorForbidden|StatementsConflict|StatementsPayloadTooLarge|StatementsUnprocessableEntity|StatementsInternalServerError {
        Statement[] submitted = payload.items ?: [];
        foreach Statement item in submitted {
            if !balancesReconcile(item) {
                return <StatementsUnprocessableEntity>{
                    body: {
                        items: [
                            {
                                feedConnectionId: item.feedConnectionId,
                                status: "REJECTED",
                                errors: [
                                    {
                                        'type: "invalid-end-balance",
                                        title: "Invalid End Balance",
                                        status: 422,
                                        detail: "End balance does not match start balance +/- statement line amounts."
                                    }
                                ]
                            }
                        ]
                    }
                };
            }
        }
        Statement[] results = [];
        lock {
            Statement[] acc = [];
            foreach Statement item in submitted.clone() {
                string? feedConnectionId = item.feedConnectionId;
                if feedConnectionId is () || !store.feedConnections.hasKey(feedConnectionId) {
                    acc.push({
                        feedConnectionId,
                        status: "REJECTED",
                        errors: [
                            {
                                'type: "invalid-feed-connection",
                                title: "Invalid Feed Connection",
                                status: 403,
                                detail: "The feed connection is not valid for this organisation."
                            }
                        ]
                    });
                    continue;
                }
                string id = nextMockId(store, "d69b02b7-a30c-464a-99cf-");
                Statement created = item.clone();
                created.id = id;
                created.status = "DELIVERED";
                created.statementLineCount = (item.statementLines ?: []).length();
                store.statements[id] = created;
                acc.push({id, feedConnectionId, status: "PENDING"});
            }
            results = acc.cloneReadOnly();
        }
        return <StatementsAccepted>{body: {items: results}};
    }
}

// Seeds the store with one feed connection and one delivered statement.
isolated function seedStore() returns MockStore {
    FeedConnection feedConnection = {
        id: MOCK_FEED_CONNECTION_ID,
        accountToken: "foobar31306",
        accountType: "BANK",
        accountNumber: "123496842",
        accountName: "SDK Bank 95921",
        accountId: "aefbf6be-4285-4ca5-bf39-0f486c8515c7",
        currency: "GBP",
        country: "GB"
    };
    Statement statement = {
        id: MOCK_STATEMENT_ID,
        feedConnectionId: MOCK_FEED_CONNECTION_ID,
        status: "DELIVERED",
        startDate: "2019-08-11",
        endDate: "2019-10-11",
        startBalance: {amount: 100.00, creditDebitIndicator: "CREDIT"},
        endBalance: {amount: 150.00, creditDebitIndicator: "CREDIT"},
        statementLineCount: 1,
        statementLines: [
            {
                postedDate: "2019-09-02",
                description: "Refund for returned goods",
                amount: 50.00,
                creditDebitIndicator: "CREDIT",
                transactionId: "transaction-id-1",
                payeeName: "Northwind Traders",
                reference: "Order 1001",
                transactionType: "Refund"
            }
        ]
    };
    return {
        feedConnections: {[MOCK_FEED_CONNECTION_ID]: feedConnection},
        statements: {[MOCK_STATEMENT_ID]: statement},
        nextId: 1
    };
}

// Returns a new UUID-shaped identifier. Must be called while holding the lock on `store`.
isolated function nextMockId(MockStore current, string prefix) returns string {
    string suffix = current.nextId.toString();
    current.nextId += 1;
    while suffix.length() < 12 {
        suffix = "0" + suffix;
    }
    return prefix + suffix;
}

// Whether a statement's end balance equals its start balance plus the signed line amounts.
isolated function balancesReconcile(Statement statement) returns boolean {
    StartBalance? startBalance = statement.startBalance;
    EndBalance? endBalance = statement.endBalance;
    if startBalance is () || endBalance is () {
        return true;
    }
    decimal balance = signed(startBalance.amount ?: 0d, startBalance.creditDebitIndicator);
    foreach StatementLine line in statement.statementLines ?: [] {
        balance += signed(line.amount ?: 0d, line.creditDebitIndicator);
    }
    return balance == signed(endBalance.amount ?: 0d, endBalance.creditDebitIndicator);
}

isolated function signed(decimal amount, CreditDebitIndicator? indicator) returns decimal =>
    indicator == "DEBIT" ? -amount : amount;

// Returns [first index, end index, page, page size] for a 1-based page request.
isolated function pageBounds(int total, int? page, int? pageSize) returns [int, int, int, int] {
    int size = pageSize is int && pageSize > 0 ? pageSize : 10;
    int currentPage = page is int && page > 0 ? page : 1;
    int first = int:min((currentPage - 1) * size, total);
    int last = int:min(first + size, total);
    return [first, last, currentPage, size];
}

isolated function pageCount(int total, int size) returns int => total == 0 ? 0 : (total + size - 1) / size;

// Service-mode response types. `bal openapi --mode client` collapses 4XX/5XX
// to `error` and never emits these, so they are defined here for the mock only.
public type ErrorForbidden record {|
    *http:Forbidden;
    Error body;
|};

public type FeedConnectionsAccepted record {|
    *http:Accepted;
    FeedConnections body;
|};

public type FeedConnectionsBadRequest record {|
    *http:BadRequest;
    FeedConnections body;
|};

public type StatementsAccepted record {|
    *http:Accepted;
    Statements body;
|};

public type StatementsBadRequest record {|
    *http:BadRequest;
    Statements body;
|};

public type StatementsConflict record {|
    *http:Conflict;
    Statements body;
|};

public type StatementsInternalServerError record {|
    *http:InternalServerError;
    Statements body;
|};

public type StatementsPayloadTooLarge record {|
    *http:PayloadTooLarge;
    Statements body;
|};

public type StatementsUnprocessableEntity record {|
    *http:UnprocessableEntity;
    Statements body;
|};
