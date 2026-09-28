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

// Connects a customer's bank account to their Xero organisation as a bank feed, confirms
// the connection Xero recorded, lists every feed connection in the organisation, and
// optionally disconnects the new feed again.

import ballerina/io;
import ballerinax/xero.bankfeeds;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
// Your institution's own identifier for the account. It must be unique within your institution.
configurable string accountToken = ?;
// The full account number, or only the last four digits for a credit card.
configurable string accountNumber = ?;
configurable string accountName = ?;
// BANK or CREDITCARD.
configurable string accountType = "BANK";
// ISO-4217 currency code of the account.
configurable string currency = ?;
// Disconnecting is off by default: it removes the feed that this example has just created.
configurable boolean disconnectAfterwards = false;

const int PAGE_SIZE = 50;

public function main() returns error? {
    bankfeeds:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });
    bankfeeds:CurrencyCode currencyCode = check currency.ensureType();
    if accountType != "BANK" && accountType != "CREDITCARD" {
        return error(string `accountType must be BANK or CREDITCARD, not '${accountType}'`);
    }
    "BANK"|"CREDITCARD" feedAccountType = accountType == "CREDITCARD" ? "CREDITCARD" : "BANK";

    // Step 1: ask Xero to connect the account to the organisation.
    bankfeeds:FeedConnections submitted = check xero->createFeedConnections({xeroTenantId: tenantId}, {
        items: [
            {
                accountToken,
                accountNumber,
                accountName,
                accountType: feedAccountType,
                currency: currencyCode
            }
        ]
    });
    bankfeeds:FeedConnection[] results = submitted.items ?: [];
    if results.length() == 0 {
        return error("Xero returned no result for the feed connection request");
    }
    bankfeeds:FeedConnection result = results[0];
    if result.status == "REJECTED" {
        bankfeeds:Error? reason = result.'error;
        return error(string `Xero rejected the feed connection: ${reason?.title ?: "no reason given"} (${reason?.detail ?: ""})`);
    }
    string feedConnectionId = check result.id.ensureType();
    io:println(string `Requested feed connection ${feedConnectionId} for account token ${accountToken}`);

    // Step 2: read back the feed connection Xero recorded.
    bankfeeds:FeedConnection connection = check xero->getFeedConnection(feedConnectionId, {xeroTenantId: tenantId});
    string recordedType = connection.accountType ?: feedAccountType;
    string recordedCurrency = connection.currency ?: currencyCode;
    io:println(string `Feed connection ${feedConnectionId}: ${connection.accountName ?: accountName}, `
        + string `${recordedType}, ${recordedCurrency}, `
        + string `linked to Xero bank account ${connection.accountId ?: "(not yet linked)"}`);

    // Step 3: list every feed connection in the organisation, one page at a time.
    int page = 1;
    int total = 0;
    while true {
        bankfeeds:FeedConnections current = check xero->getFeedConnections({xeroTenantId: tenantId},
            page = page, pageSize = PAGE_SIZE);
        bankfeeds:FeedConnection[] items = current.items ?: [];
        foreach bankfeeds:FeedConnection item in items {
            string marker = item.id == feedConnectionId ? " (new)" : "";
            io:println(string `  ${item.id ?: "-"}  ${item.accountToken ?: "-"}  ${item.accountName ?: "-"}${marker}`);
        }
        total += items.length();
        if items.length() < PAGE_SIZE {
            break;
        }
        page += 1;
    }
    io:println(string `The organisation has ${total} feed connection(s)`);

    // Step 4: optionally disconnect the feed again.
    if disconnectAfterwards {
        bankfeeds:FeedConnections deleted = check xero->deleteFeedConnections({xeroTenantId: tenantId}, {
            items: [{id: feedConnectionId}]
        });
        bankfeeds:FeedConnection[] deleteResults = deleted.items ?: [];
        if deleteResults.length() == 0 || deleteResults[0].status == "REJECTED" {
            return error(string `Xero did not accept the request to disconnect ${feedConnectionId}`);
        }
        io:println(string `Requested disconnection of feed connection ${feedConnectionId}`);
    }
}

