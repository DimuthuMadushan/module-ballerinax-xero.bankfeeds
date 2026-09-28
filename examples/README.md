# Examples

The `ballerinax/xero.bankfeeds` connector provides practical examples illustrating usage in various scenarios.

| Example | Description |
|---------|-------------|
| [`bank_feed_connection_lifecycle`](./bank_feed_connection_lifecycle/bank_feed_connection_lifecycle.md) | Connects a bank account to a Xero organisation as a bank feed, confirms it and lists every feed connection. |
| [`deliver_daily_bank_statement`](./deliver_daily_bank_statement/deliver_daily_bank_statement.md) | Delivers one day's transactions to a feed connection as a statement and checks its delivery status. |

## Prerequisites

1. Complete the [setup guide](../ballerina/README.md#setup-guide) to obtain a client ID, client secret, refresh token and tenant ID for a Xero app with the `bankfeeds` scope.

2. For each example, create a `Config.toml` in the example directory with the required credentials and the example-specific values listed in its document:
   ```toml
   clientId = "<CLIENT_ID>"
   clientSecret = "<CLIENT_SECRET>"
   refreshToken = "<REFRESH_TOKEN>"
   refreshUrl = "https://identity.xero.com/connect/token"
   tenantId = "<TENANT_ID>"
   ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
