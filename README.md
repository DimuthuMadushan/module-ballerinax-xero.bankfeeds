# Ballerina Xero Bank Feeds connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-xero.bankfeeds/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-xero.bankfeeds/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-xero.bankfeeds.svg)](https://github.com/ballerina-platform/module-ballerinax-xero.bankfeeds/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/xero.bankfeeds.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fxero.bankfeeds)

## Overview

[Xero](https://www.xero.com/) is a cloud-based accounting platform for small and medium-sized businesses. Its bank feeds deliver a business's bank transactions straight into Xero, where they are reconciled against invoices, bills and payments.

The Ballerina Xero Bank Feeds connector lets you work with the [Xero Bank Feeds API](https://developer.xero.com/documentation/bank-feeds-api/overview) from Ballerina: connect a financial institution's customer accounts to their Xero organisations as bank feeds, and deliver bank statements and statement lines to those feeds. The Bank Feeds API is a closed API, available only to financial institutions that have an established financial services partnership with Xero.

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

1. [Bank feed connection lifecycle](examples/bank_feed_connection_lifecycle/bank_feed_connection_lifecycle.md) - Connects a bank account to a Xero organisation as a bank feed, confirms the connection, lists every feed connection and optionally disconnects the new feed.
2. [Deliver a daily bank statement](examples/deliver_daily_bank_statement/deliver_daily_bank_statement.md) - Turns one day's transactions into a bank statement, delivers it to a feed connection and checks its delivery status.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`xero.bankfeeds` package](https://central.ballerina.io/ballerinax/xero.bankfeeds/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
