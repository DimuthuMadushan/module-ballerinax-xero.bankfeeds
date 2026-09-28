## Overview

[Xero](https://www.xero.com/) is a cloud-based accounting platform for small and medium-sized businesses. Its bank feeds deliver a business's bank transactions straight into Xero, where they are reconciled against invoices, bills and payments.

The Ballerina Xero Bank Feeds connector lets you work with the [Xero Bank Feeds API](https://developer.xero.com/documentation/bank-feeds-api/overview) from Ballerina: connect a financial institution's customer accounts to their Xero organisations as bank feeds, and deliver bank statements and statement lines to those feeds. The Bank Feeds API is a closed API, available only to financial institutions that have an established financial services partnership with Xero.

### Key features

- Connect customers' bank and credit card accounts to their Xero organisations as bank feeds
- Look up, list and disconnect the feed connections in an organisation
- Deliver bank statements, with opening and closing balances and their transaction lines, to a feed connection
- Retry statement and feed connection requests safely with idempotency keys
- Track the delivery status of every statement, including the reasons Xero rejected one

## Setup guide

To use the connector you need access to the Xero Bank Feeds API, an app registered in the Xero developer portal, an OAuth 2.0 refresh token with the `bankfeeds` scope and the ID of the organisation (tenant) to work with.

1. Get access to the Bank Feeds API. It is only available to financial institutions with an established [Xero financial services partnership](https://developer.xero.com/documentation/bank-feeds-api/overview). Existing partners request access through their Xero Partner Manager, and Xero enables the `bankfeeds` scope for the partner's app.

2. Sign in to the [Xero developer portal](https://developer.xero.com/app/manage) and select **New app**. Choose the **Web app** integration type, enter an app name, a company or application URL, and a redirect URI such as `http://localhost:8080/callback`, then create the app.

3. On the app's **Configuration** page, copy the **Client id** and generate a **Client secret**. Keep the secret safe; it is shown only once.

4. Obtain a refresh token with the [OAuth 2.0 authorization code flow](https://developer.xero.com/documentation/guides/oauth2/auth-flow). Open the authorization URL below in a browser, replacing the client ID and redirect URI with your own. `offline_access` is required to receive a refresh token, and `bankfeeds` grants access to the Bank Feeds API.

   ```
   https://login.xero.com/identity/connect/authorize?response_type=code&client_id=<CLIENT_ID>&redirect_uri=<REDIRECT_URI>&scope=openid profile email offline_access bankfeeds&state=123
   ```

   After you approve access, Xero redirects to your redirect URI with a `code` query parameter. Exchange it for tokens:

   ```bash
   curl -X POST https://identity.xero.com/connect/token \
     -u "<CLIENT_ID>:<CLIENT_SECRET>" \
     -d grant_type=authorization_code \
     -d code=<CODE> \
     -d redirect_uri=<REDIRECT_URI>
   ```

   The response contains an `access_token` and a `refresh_token`.

5. Every Bank Feeds API call is scoped to an organisation through the `Xero-Tenant-Id` header. List the organisations the token can access and note the `tenantId` of the one you want:

   ```bash
   curl https://api.xero.com/connections -H "Authorization: Bearer <ACCESS_TOKEN>"
   ```

## Quickstart

To use the Xero Bank Feeds connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `xero.bankfeeds` module.

```ballerina
import ballerinax/xero.bankfeeds;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with the credentials from the setup guide:

    ```toml
    clientId = "<CLIENT_ID>"
    clientSecret = "<CLIENT_SECRET>"
    refreshToken = "<REFRESH_TOKEN>"
    refreshUrl = "https://identity.xero.com/connect/token"
    tenantId = "<TENANT_ID>"
    ```

2. Create a `bankfeeds:Client` that refreshes its access token with those credentials:

    ```ballerina
    configurable string clientId = ?;
    configurable string clientSecret = ?;
    configurable string refreshToken = ?;
    configurable string refreshUrl = ?;
    configurable string tenantId = ?;

    final bankfeeds:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });
    ```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations. Every operation takes the tenant ID in its headers record.

#### List the organisation's feed connections

```ballerina
public function main() returns error? {
    bankfeeds:FeedConnections _ = check xero->getFeedConnections({xeroTenantId: tenantId}, page = 1, pageSize = 50);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The Xero Bank Feeds connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-xero.bankfeeds/tree/main/examples/), covering the following use cases:

1. [Bank feed connection lifecycle](../examples/bank_feed_connection_lifecycle/bank_feed_connection_lifecycle.md) - Connects a bank account to a Xero organisation as a bank feed, confirms the connection, lists every feed connection and optionally disconnects the new feed.
2. [Deliver a daily bank statement](../examples/deliver_daily_bank_statement/deliver_daily_bank_statement.md) - Turns one day's transactions into a bank statement, delivers it to a feed connection and checks its delivery status.
