# Deliver a daily bank statement

This example turns one day's transactions from a core banking system into a Xero bank statement and delivers it to an existing feed connection. It first checks that no statement for that day has already been delivered, then works out the closing balance from the opening balance and the transactions, sends the statement with an idempotency key that protects an immediate retry of the same request, and checks the delivery status Xero reports. It then pages through the statements already delivered and counts those for the feed connection by status.

## Prerequisites

- A Xero app with the `bankfeeds` scope, a refresh token and a tenant ID, as described in the [setup guide](../../ballerina/README.md#setup-guide). The Bank Feeds API is only available to approved Xero financial services partners.
- An active feed connection to deliver the statement to. The [bank feed connection lifecycle](../bank_feed_connection_lifecycle/bank_feed_connection_lifecycle.md) example creates one.
- Push the connector to the local repository:
  ```bash
  (cd ../../ballerina && bal pack && bal push --repository=local)
  ```
- Create a `Config.toml` in this directory:
  ```toml
  clientId = "<CLIENT_ID>"
  clientSecret = "<CLIENT_SECRET>"
  refreshToken = "<REFRESH_TOKEN>"
  refreshUrl = "https://identity.xero.com/connect/token"
  tenantId = "<TENANT_ID>"
  feedConnectionId = "<FEED_CONNECTION_ID>"
  # The statement date, in YYYY-MM-DD format. It can be no older than one year.
  statementDate = "<YYYY-MM-DD>"
  # The account balance at the start of the day. A negative value is an overdrawn balance.
  openingBalance = 1500.00
  ```

## Run the example

```bash
bal run
```
