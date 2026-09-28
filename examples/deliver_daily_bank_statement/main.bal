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

// Turns one day's transactions from a core banking system into a Xero bank statement,
// delivers it to a feed connection, checks its delivery status, and summarises the
// statements already delivered to that feed.

import ballerina/io;
import ballerinax/xero.bankfeeds;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
// The feed connection to deliver the statement to, from GET FeedConnections.
configurable string feedConnectionId = ?;
// The statement date, in YYYY-MM-DD format. It can be no older than one year.
configurable string statementDate = ?;
// The account balance at the start of the day. A negative value is an overdrawn balance.
configurable decimal openingBalance = ?;

const int PAGE_SIZE = 50;

// A transaction as the core banking system records it: credits positive, debits negative.
type BankTransaction record {|
    string id;
    string description;
    string payee;
    decimal amount;
    string transactionType;
|};

public function main() returns error? {
    bankfeeds:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });

    // Step 1: build the statement from the day's transactions.
    BankTransaction[] transactions = [
        {id: statementDate + "-0001", description: "Salary payment", payee: "Contoso Ltd", amount: 3200.00, transactionType: "Credit transfer"},
        {id: statementDate + "-0002", description: "Card purchase", payee: "Northwind Grocers", amount: -86.45, transactionType: "Card"},
        {id: statementDate + "-0003", description: "Direct debit", payee: "Fabrikam Energy", amount: -142.10, transactionType: "Direct debit"}
    ];
    decimal closingBalance = openingBalance;
    bankfeeds:StatementLine[] lines = [];
    foreach BankTransaction txn in transactions {
        closingBalance += txn.amount;
        lines.push({
            postedDate: statementDate,
            description: txn.description,
            payeeName: txn.payee,
            amount: txn.amount.abs(),
            creditDebitIndicator: txn.amount < 0d ? "DEBIT" : "CREDIT",
            transactionId: txn.id,
            transactionType: txn.transactionType
        });
    }

    // Step 2: deliver the statement. The idempotency key makes a retry of the same day safe.
    bankfeeds:Statements submitted = check xero->createStatements(
        {xeroTenantId: tenantId, idempotencyKey: string `${feedConnectionId}-${statementDate}`},
        {
            items: [
                {
                    feedConnectionId,
                    startDate: statementDate,
                    endDate: statementDate,
                    startBalance: balance(openingBalance),
                    endBalance: balance(closingBalance),
                    statementLines: lines
                }
            ]
        }
    );
    bankfeeds:Statement[] results = submitted.items ?: [];
    if results.length() == 0 {
        return error("Xero returned no result for the statement");
    }
    if results[0].status == "REJECTED" {
        return error("Xero rejected the statement: " + describeErrors(results[0].errors));
    }
    string statementId = check results[0].id.ensureType();
    io:println(string `Delivered statement ${statementId} with ${lines.length()} line(s), `
        + string `opening ${openingBalance}, closing ${closingBalance}`);

    // Step 3: check the delivery status Xero now reports for the statement.
    bankfeeds:Statement statement = check xero->getStatement(statementId, {xeroTenantId: tenantId});
    io:println(string `Statement ${statementId} status: ${statement.status ?: "unknown"}`);
    if statement.status == "REJECTED" {
        io:println("  " + describeErrors(statement.errors));
    }

    // Step 4: summarise every statement delivered to this feed connection, one page at a time.
    map<int> countsByStatus = {};
    int page = 1;
    while true {
        bankfeeds:Statements current = check xero->getStatements({xeroTenantId: tenantId},
            page = <int:Signed32>page, pageSize = PAGE_SIZE);
        bankfeeds:Statement[] items = current.items ?: [];
        foreach bankfeeds:Statement item in items {
            if item.feedConnectionId == feedConnectionId {
                string status = item.status ?: "UNKNOWN";
                countsByStatus[status] = (countsByStatus[status] ?: 0) + 1;
            }
        }
        if items.length() < PAGE_SIZE {
            break;
        }
        page += 1;
    }
    io:println(string `Statements for feed connection ${feedConnectionId}:`);
    foreach [string, int] [status, count] in countsByStatus.entries() {
        io:println(string `  ${status}: ${count}`);
    }
}

// Converts a signed balance to the unsigned amount and credit/debit indicator Xero expects.
function balance(decimal amount) returns record {|decimal amount; bankfeeds:CreditDebitIndicator creditDebitIndicator;|} =>
    {amount: amount.abs(), creditDebitIndicator: amount < 0d ? "DEBIT" : "CREDIT"};

function describeErrors(bankfeeds:Error[]? errors) returns string {
    string[] messages = from bankfeeds:Error e in errors ?: []
        select string `${e.title ?: "Error"}: ${e.detail ?: ""}`;
    return messages.length() == 0 ? "no reason given" : string:'join("; ", ...messages);
}
