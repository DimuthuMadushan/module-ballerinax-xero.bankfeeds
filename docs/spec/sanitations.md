_Author_: @DimuthuMadushan \
_Created_: 2026/09/28 \
_Updated_: 2026/10/05 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Xero Bank Feeds. 
The OpenAPI specification is obtained from the [Xero Bank Feeds API 19.0.0 specification](https://github.com/wso2/api-specs/blob/main/openapi/xero/bankfeeds/19.0.0/openapi.yaml) (`openapi/xero/bankfeeds/19.0.0/openapi.yaml` in `api-specs`), which is Xero's own `xero_bankfeeds.yaml` from [XeroAPI/Xero-OpenAPI](https://github.com/XeroAPI/Xero-OpenAPI).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

Items 1, 3 to 7 and 9 are applied directly to `docs/spec/openapi.yaml`, so they survive every regeneration. Item 2 is a note on how the aligned YAML is converted to JSON, and item 8 is recorded in `ai-mappings.json`. Apart from the `NO` quoting in item 1, `flatten` and `align` made no structural changes to this specification: no server URL, path prefix, format, nullability or type changes.

1. **Quoted the `NO` (Norway) value of the `CountryCode` enum**
   **Original**: The `CountryCode` enum lists Norway as an unquoted `- NO`. YAML 1.1 reads an unquoted `NO` as the boolean `false`, and `bal openapi flatten` wrote it to the flattened specification as the string `"false"`.
   **Updated**: The enum value is quoted, `- "NO"`, between `NL` and `NP`, so flatten keeps the string `"NO"`.
   **Reason**: `CountryCode` is generated as a closed union of string literals, so with `"false"` in place of `"NO"` a feed connection whose `country` is Norway could neither be created nor read back.

2. **Converted the aligned YAML to JSON without timestamp coercion**
   **Original**: The response examples contain unquoted dates (for example `startDate: 2019-08-01`).
   **Updated**: 15 example values are kept as the strings written in the specification.
   **Reason**: PyYAML resolves unquoted dates to `date` objects, which the JSON encoder rejects, so the plugin's YAML-to-JSON conversion fails. Loading without the timestamp resolver keeps the values unchanged.

3. **Added descriptions to undocumented schemas, properties and headers**
   **Original**: `FeedConnection`, `FeedConnections`, `Statement`, `Statements`, `StatementLines` and `Pagination` had no description; neither did 16 properties (for example `FeedConnection.country`, `Statement.startBalance`, `Statement.statementLineCount`, `EndBalance.amount`, the `items` and `pagination` properties of `FeedConnections` and `Statements`) or the `Xero-Application-Id` and `Xero-User-Id` headers of `GET /Statements`.
   **Updated**: Each has a description derived from its schema and purpose, for example "Opening balance of the statement", "List of feed connections" and "Xero identifier of the application making the request".
   **Reason**: Undocumented schemas, properties and headers produce undocumented types, record fields and header fields in the generated `types.bal`.

4. **Wrapped 11 bare `$ref` properties in `allOf`**
   **Original**: `FeedConnection.country`, `currency` and `error`, `Statement.statementLines`, `startBalance` and `endBalance`, the three `creditDebitIndicator` properties and the two `pagination` properties were a bare `$ref`.
   **Updated**: `allOf: [{$ref: ...}]` with a sibling `description`.
   **Reason**: OpenAPI 3.0 ignores keys beside a bare `$ref`, and `bal openapi align` drops a `description` that sits beside one, so the description added in item 3 would otherwise be lost from the generated field.

5. **Corrected the `page` query parameter descriptions**
   **Original**: The `page` parameter of `GET /Statements` read "unique id for single object", and both `page` parameters gave `?page=1` as the example for getting the second set of records.
   **Updated**: `GET /Statements` has the same page-number description as `GET /FeedConnections`, and both examples read `?page=2`.
   **Reason**: The description becomes the doc comment of `GetStatementsQueries.page`, and the vendor text described a different parameter.

6. **Normalised five operation summaries**
   **Original**: "Create one or more new feed connection", "Retrieve single feed connection based on a unique id provided", "Delete an existing feed connection", "Retrieve all statements" and "Retrieve single statement based on unique id provided".
   **Updated**: "Creates one or more new feed connections", "Retrieves a single feed connection by its unique ID", "Deletes one or more existing feed connections", "Retrieves all statements" and "Retrieves a single statement by its unique ID".
   **Reason**: The summary becomes the remote method's doc comment. The rewrite fixes the grammar, matches the verb form of the other two operations, and reflects that `deleteFeedConnections` takes a list of feed connections.

7. **Rewrote the success response descriptions**
   **Original**: For example "search results matching criteria returned with pagination and items array" and "success new feed connection(s)response".
   **Updated**: For example "A page of feed connections, with pagination details" and "The submitted feed connections, each with its status".
   **Reason**: The success response description becomes the remote method's `# + return` doc comment.

8. **Kept Xero's operationIds and schema names unchanged**
   **Original**: 7 operationIds and 13 schema names.
   **Updated**: No change. The decisions are recorded as identity mappings in `ai-mappings.json`.
   **Reason**: The operationIds are the remote method names that `ballerinax/xero.bankfeeds` 1.x published, so keeping them keeps every 1.x method name.

9. **Made the statement response examples numeric**
   **Original**: The `GET /Statements` and `GET /Statements/{statementId}` response examples gave `statementLineCount` as `"1"` and the `startBalance` and `endBalance` amounts as `"100.0000"` and `"150.0000"`, all strings.
   **Updated**: The three statement examples give `statementLineCount: 1` and the balance amounts as the numbers `100.0000` and `150.0000`.
   **Reason**: The schema types `statementLineCount` as an integer and the balance amounts as numbers, generated as `int` and `decimal`, so the string examples contradicted the types they document.

The connector uses remote methods (`--client-methods remote`), as 1.x did.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json --mode client --client-methods remote --license docs/license.txt -o ballerina
```
Note: The license year is 2026, as set in `docs/license.txt`.
