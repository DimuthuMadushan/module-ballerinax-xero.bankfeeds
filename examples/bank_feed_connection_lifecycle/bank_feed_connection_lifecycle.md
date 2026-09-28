# Bank feed connection lifecycle

This example connects one of a customer's bank accounts to their Xero organisation as a bank feed. It requests the feed connection, reads back what Xero recorded for it, and lists every feed connection in the organisation page by page. It can then disconnect the new feed again, which is off by default.

## Prerequisites

- A Xero app with the `bankfeeds` scope, a refresh token and a tenant ID, as described in the [setup guide](../../ballerina/README.md#setup-guide). The Bank Feeds API is only available to approved Xero financial services partners.
- Push the connector to the local repository:
  ```bash
  cd ../../ballerina
  bal pack && bal push --repository=local
  ```
- Create a `Config.toml` in this directory:
  ```toml
  clientId = "<CLIENT_ID>"
  clientSecret = "<CLIENT_SECRET>"
  refreshToken = "<REFRESH_TOKEN>"
  refreshUrl = "https://identity.xero.com/connect/token"
  tenantId = "<TENANT_ID>"
  # Your institution's own identifier for the account, unique within your institution.
  accountToken = "<ACCOUNT_TOKEN>"
  # The full account number, or only the last four digits for a credit card.
  accountNumber = "<ACCOUNT_NUMBER>"
  accountName = "<ACCOUNT_NAME>"
  # BANK or CREDITCARD.
  accountType = "BANK"
  # ISO-4217 currency code of the account, for example GBP.
  currency = "<CURRENCY_CODE>"
  # Removes the feed this example has just created.
  disconnectAfterwards = false
  ```

## Run the example

```bash
bal run
```
