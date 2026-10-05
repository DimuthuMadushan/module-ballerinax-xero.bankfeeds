# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Per-operation headers records (`GetFeedConnectionsHeaders`, `CreateStatementsHeaders`, …) and queries records (`GetFeedConnectionsQueries`, `GetStatementsQueries`).
- The optional `Idempotency-Key` header on `createFeedConnections`, `deleteFeedConnections` and `createStatements`, so a request can be retried without being processed twice.
- Documentation for every record type and field, and two examples: connecting a bank feed, and delivering a daily bank statement.

### Changed

- The connector is regenerated from the Xero Bank Feeds API specification 19.0.0 and requires Ballerina 2201.12.0 or later. It keeps the same seven operations and remote method names as 1.x, but it is not source-compatible with 1.x.
- Request headers are passed as a headers record instead of leading positional arguments. For example, `getFeedConnection(xeroTenantId, id)` is now `getFeedConnection(id, {xeroTenantId: tenantId})`, and `getStatements(xeroTenantId, page, pageSize, xeroApplicationId, xeroUserId)` is now `getStatements({xeroTenantId: tenantId}, page = 1, pageSize = 10)`.
- Optional query parameters are passed as named arguments (`page = 1, pageSize = 10`), and on `getStatements` they are typed `int:Signed32`.
- `CountryCode`, `CurrencyCode` and `CreditDebitIndicator` are unions of their allowed values instead of `string`, and so are `FeedConnection.accountType` and `status`, `Statement.status` and `Error.type`.

