# Tests

The test suite exercises all 7 of the connector's operations against a mock Xero Bank Feeds API: feed connections (`getFeedConnections`, `getFeedConnection`, `createFeedConnections`, `deleteFeedConnections`) and statements (`getStatements`, `getStatement`, `createStatements`). The mock keeps the feed connections and statements it is sent, so a lookup returns what an earlier call created. Each delete test creates the feed connection it deletes, so tests do not depend on execution order or shared fixtures. Two mock-only tests check rejections: deleting a feed connection that has already been deleted, and posting a statement whose end balance does not equal its start balance plus its line amounts.

## Running Tests

```bash
bal test
```

The test suite uses a mock server (`tests/mock_service.bal`) that intercepts HTTP calls so no real credentials are required.

### Running against Xero

Tests in the `live_tests` group can run against a real Xero organisation. The Bank Feeds API is only available to approved Xero financial services partners, so use an app that has the `bankfeeds` scope and a demo organisation. The tests create feed connections and a statement, and delete one of the feed connections they create.

| Variable | Description |
|---|---|
| `IS_LIVE_SERVER` | Set to `true` to run against Xero instead of the mock |
| `XERO_ACCESS_TOKEN` | OAuth 2.0 access token with the `bankfeeds` scope |
| `XERO_TENANT_ID` | Xero tenant (organisation) ID, sent as the `Xero-Tenant-Id` header |
| `XERO_FEED_CONNECTION_ID` | ID of an existing, active feed connection in that organisation |
| `XERO_STATEMENT_ID` | ID of an existing statement delivered to that organisation |

```bash
export IS_LIVE_SERVER=true
export XERO_ACCESS_TOKEN=<access token>
export XERO_TENANT_ID=<tenant id>
export XERO_FEED_CONNECTION_ID=<feed connection id>
export XERO_STATEMENT_ID=<statement id>
bal test --groups live_tests
```
