## Overview <!-- markdownlint-disable-line MD041 -->

This discussion is for communicating to adapter maintainers the scope of work needed to make use of the changes in 1.7.0. If you have questions and concerns, please ask them here for posterity.

Please consider this a living document between now and the date of final release. If there's something missing, please comment below!

<details><summary>

### Loom video overview (12 min)

</summary>

<div>     <a href="https://www.loom.com/share/594dd3b0f85848baa2a3a998c218807c">       <p>Adapter Maintainers: Upgrading to dbt-core v1.7.0 - Watch Video</p>     </a>     <a href="https://www.loom.com/share/594dd3b0f85848baa2a3a998c218807c">       <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/594dd3b0f85848baa2a3a998c218807c-with-play.gif">     </a>   </div>

</details>

### release timeline

The below table gives the milestones between up to and including the final release. It will be updated with each subsequent release.

- [x] #8261
- [x] #8262
- [ ] #8263
- [ ] Release v1.7.0 to cloud October 30

<details><summary>

### prior maintainer upgrade guides

</summary>

- #7958
- #7213
- #6624
- #6011
- #5468

</details>

### Example Diffs

- <https://github.com/dbt-labs/dbt-redshift/compare/v1.6.0...v1.7.latest>
- <https://github.com/dbt-labs/dbt-bigquery/compare/v1.6.0...v1.7.latest>
- <https://github.com/dbt-labs/dbt-snowflake/compare/v1.6.0...v1.7.latest>
- <https://github.com/dbt-labs/dbt-spark/compare/v1.6.0...v1.7.latest>

## TL;DR

Excluding the work to consume our refactoring work for materialized views, there should be no breaking changes. Please tell me if I'm wrong, but I believe that things should work by bumping package and dependency versions. I recommend adding tests. Everything below is nice-to-have first steps toward long-term stable interfaces we will develop in future versions.

## Changes

### new capability support structure for adapters

`dbt-core 1.7.0` improves performance of two existing features: source freshness and catalog metadata fetching (see below for more).  However, these improvements are only available contingent upon underlying data platform support.

Traditionally, this adapter interface to call this out would be a single jinja macro or python method that may be overridden accordingly, but the end result is one macro that varies in what it does across adapters.

Our solution here is to define adapter/database capability in a top-level structure, that then "dispatches" to the corresponding macro/function. This way there's a stronger separation of concerns.

A new static member variable on `BaseAdapter` called `_capabilities` with type [`CapabilityDict`](https://github.com/dbt-labs/dbt-core/blob/1baebb423c82a9c645e59b390fc3a69089623600/core/dbt/adapters/base/impl.py#L240-L242) can be overriden by adapter implementations. This new member variable is introduced to more easily flag to dbt-core whether or not a database supports a given dbt feature. [`dbt/adapters/capability.py`](https://github.com/dbt-labs/dbt-core/blob/1baebb423c82a9c645e59b390fc3a69089623600/core/dbt/adapters/capability.py) has great information on how it's structured.

From `1.7` forward, for a given relevant feature we'll define a new Capability within the Capability class, so that it may be defined within an adapter. The possible support states are defined within the [`Support` class](https://github.com/dbt-labs/dbt-core/blob/26a0ec61def58afc8d875b1f54a8262c4c9bd59b/core/dbt/adapters/capability.py#L17C1-L34C1), namely: "Unknown", "Unsupported", "NotImplemented", "Versioned", or "Full".

If you as an adaper maintainer want to define that your dataplatform has does not support a new feature, `SomeNewFeature`, you'd define it as the below.

```py
_capabilities: CapabilityDict = CapabilityDict(
    {Capability.SomeNewFeature: CapabilitySupport(support=Support.Unsupported)}
)
```

I'm very excited at the potential of this feature. I can imagine that much of an adapter might be abstracted into a structure like this, so that where previously a macro-override was required, now it's just another Dict entry.

### metadata freshness checks

#7012 #8704 #8795 <https://github.com/dbt-labs/dbt-snowflake/pull/796> <!-- markdownlint-disable-line MD018 -->

#### Excerpt from #7102

> Currently, source freshness can only be determined by querying a column in a table. When there are a lot of tables, even with a high number of threads, the amount of time it takes to compute source freshness might be unacceptably long - it's effectively just metadata collation after all.
> However, lots of databases track table modification times (although don't always isolate DDL changes from DML changes) and expose this via a metadata route. For example, BigQuery has the well-known INFORMATION_SCHEMA tables which expose various metadata attributes.

#### How to implement

> [!NOTE]
> This is the first of the two new features enabled via the new Capability dict.
<!-- markdownlint-disable-line MD028 -->
> [!WARNING]
> if you're overriding `Adapter.calculate_freshness()` the type signature has changed so please update accordingly: [dbt-core#8795#discussion_r1355356418](https://github.com/dbt-labs/dbt-core/pull/8795#discussion_r1355356418)

If your data platform has `Full` support for this new functionality, you will need to:

1. add a new entry within the `_capabilities` Dict (see above section) to define. in this case, the feature is `TableLastModifiedMetadata`. See [dbt-snowflake#796#impl.py](https://github.com/dbt-labs/dbt-snowflake/pull/796/files#diff-3b8dfc96ca09cc82325269902a1353fa14e4503308502ba4c64f24e037734bdb) for the change that's needed.
2. add a dispatched `get_relation_last_modified()` to define how to fetch this freshness metadata with a new macro. Note that `default__get_relation_last_modified()` is not implemented, so you must implement your own. See [`snowflake__get_relation_last_modified()`](https://github.com/dbt-labs/dbt-snowflake/blob/cf854b5c1c9b6b8e9b84e77c4f27b4ede3fc47df/dbt/include/snowflake/macros/metadata.sql). The function signature is similar to that of the below described `get_catalog_tables_sql()`, but returns a table with four columns:
    1. `schema`
    2. `identifier`,
    3. `last_modified` the actual freshness metadata of the table
    4. `snapshotted_at` current timestamp so we know when dbt checks for this

#### Freshness Tests

- `TestGetLastRelationModified`
- `TestListRelationsWithoutCaching` has been deprecated and broken into the following:
    - `TestListRelationsWithoutCachingSingle`
    - `TestListRelationsWithoutCachingFull`

### Catalog fetch performance improvements

#8521 #8648 [dbt-snowflake#758](https://github.com/dbt-labs/dbt-snowflake/pull/758) <!-- markdownlint-disable-line MD018 -->

> [!NOTE]
> This is the second of the two new features enabled via the new Capability dict.

The performance of parsing projects and generating documentation has always become a bottleneck when one of the two conditions are met:

- Projects grow very large (10,000+ models), or
- Projects are defined within databases and schemas that contain many pre-existing objects

A change for `1.7` addresses the second scenario. The `get_catalog()` macro has always accepted a list of schemas as an argument. All the relations that exist for the given list of schemas are output, regardless of whether or not dbt interacts with this object.

The adapter implementation to solve this problem is three-fold:

1. Introduce a new macro, `get_catalog_relations()` which accepts a list of relations, rather than a list of schemas.
2. A new entry within the `_capabilities` Dict (see above section) to define whether support for `SchemaMetadataByRelations` is `Full`, `Unsupported`, or `NotImplemented`. See [dbt-snowflake#758#impl.py](https://github.com/dbt-labs/dbt-snowflake/pull/758/files#diff-3b8dfc96ca09cc82325269902a1353fa14e4503308502ba4c64f24e037734bdb) for the change that's needed.
3. Decompose the existing `get_catalog()` macro in order to minimize redundancy with body of `get_catalog_relations()`. This introduces some additional macros:
   1. `get_catalog_tables_sql()` copied straight from pre-existing `get_catalog()` everything you would normally fetch from `INFORMATION_SCHEMA.tables`
   2. `get_catalog_columns_sql()` copied straight from pre-existing `get_catalog()` everything you would normally fetch from `INFORMATION_SCHEMA.columns`
   3. `get_catalog_schemas_where_clause_sql(schemas)` copied straight from pre-existing `get_catalog()`. This uses jinja to loop through the provided schema list and make a big `WHERE` clause of the form:
       `WHERE info_schema.tables.table_schema IN "schema1" OR info_schema.tables.table_schema IN "schema2" [OR ...]`
   4. `get_catalog_relations_where_clause_sql(relations)` this is likely the only new thing

#### `get_catalog_relations_where_clause_sql`

This macro is effectively an evolution of the old `get_catalog` `WHERE` clause, except now it has the following control flow.

Keep in mind that `relation` in this instance can be a standalone schema, not necessarily an object with a three-part identifier.

```pseudocode
for relation provided list of relations
1. if relation has an identifier and a schema
    1. then write WHERE clause to filter on both
2. elif relation has a schema
    1. do what was normally done, filter where info_schema.table.table_schema == relation.schema 
3. else throw exception. Houston we do not have a something we can use.
```

The result of the above is that dbt can, with "laser-precision" fetch metadata for only the relations it needs, rather than the superset of "all the relations in all the schemas in which dbt has relations".

#### Catalog Query Structure

Where the below mentioned `OBJECT_LIST` is `relations` or `schemas` depending on the macro.

```sql
{% set query %}
    with tables as (
        {{ myadapter__get_catalog_tables_sql(information_schema) }}
        {{ myadapter__get_catalog_OBJECT_LIST_where_clause_sql(OBJECT_LIST) }}
    ),
    columns as (
        {{ myadapter__get_catalog_columns_sql(information_schema) }}
        {{ myadapter__get_catalog_OBJECT_LIST_where_clause_sql(OBJECT_LIST) }}
    )
    {{ myadapter__get_catalog_results_sql() }}
{%- endset -%}
```

#### Tests

`TestDocsGenerateOverride` in [`tests/functional/artifacts/test_override.py`](https://github.com/dbt-labs/dbt-core/blob/main/tests/functional/artifacts/test_override.py) was modified to cover this new behavior. If you are not already implementing this, I suggest that you should.

### Behavior of `dbt show`'s `--limit` flag

#8496 #8641 <!-- markdownlint-disable-line MD018 -->

`dbt show` shipped in `1.5.0` with a `--limit` flag that, when provided, would limit the number of results that dbt would grab to display. It does not modify the original query, which means that even if you provide `--limit 5`, the command will not complete until the entire underlying query is complete which can take a long time if the query's result set is large. This is especially evident because `dbt show` is now also used for dbt Cloud IDE's "preview" button.

The fix was #8641, which extends the implementation of the `--limit` flag to wrap the underlying query into a CTE and append a `LIMIT {limit}` clause.

No change is needed if the adapter's data platform supports ANSI SQL `LIMIT` clauses. Any changes can be made in a dispatched version of `get_limit_subquery_sql()`, see [`default__get_limit_subquery()`](https://github.com/dbt-labs/dbt-core/blob/53845d0277be2b0ab347ac07b84bc86363157c54/core/dbt/include/global_project/macros/adapters/show.sql#L16-L22). This was merged into `1.7.0`, but also back-ported to `1.5` and `1.6`, so if a change is needed, it will likely also need to be back-ported and patched accordingly.

`dbt.tests.adapter.dbt_show.test_dbt_show` contains new tests to ensure the new behavior functions properly:

- `BaseShowSqlHeader`
- `BaseShowLimit`

### Migrate `date_spine()` Macro from dbt-utils to Core

#8172 #8616  <!-- markdownlint-disable-line MD018 -->

Following on from initiative #5520, [dbt-utils.date_spine()](https://github.com/dbt-labs/dbt-utils/blob/main/macros/sql/date_spine.sql) (and the macros on which it directly depends) now lives within dbt-core in order to better support the semantic layer, which requires a date spine to get started.

Macros that are now testable and overridable within an adapter:

- `date_spine`
- `generate_series`
- `get_intervals_between`
- `get_powers_of_two`

The `default__` version of these macros is compatible with the adapters we currently support in dbt Cloud, with the exception of the following that should be migrated:

- Starburst/Trino, which has [`dbt-trino-utils.date_spine`](https://github.com/starburstdata/dbt-trino-utils/blob/main/macros/dbt_utils/sql/date_spine.sql),
- Fabric which has [`tsql-utils.date_spine`](https://github.com/dbt-msft/tsql-utils/blob/main/macros/dbt_utils/datetime/date_spine.sql)

#### Data Spine Tests

> [!IMPORTANT]
Important! The following test cases must be added to the adapter to ensure compatibility now and moving forward. See #8616 changes to `dbt/tests/adapter/utils/` directory for more info.

- `TestDateSpine`
- `TestGenerateSeries`
- `TestGetIntervalsBetween`
- `TestGetPowersOfTwo`

### Storing Test Failures as View

#6914 #8653  <!-- markdownlint-disable-line MD018 -->

There's a new config for tests, `store_failures_as` which can be `table` or `view`. It overlaps in "interesting" ways with an existing config, `store_failures`, which will be deprecated within the next two minor releases, i.e. either `1.8` or `1.9`

> [!NOTE]
Provided that your adapter doesn't have a custom `test` materialization overriding Core's default, there shouldn't be work required here beyond adding the below tests. But leaving this as standalone section rather than listing the available tests just in case.

#### Store Failures Tests

- `TestStoreTestFailuresAsInteractions`
- `TestStoreTestFailuresAsProjectLevelOff`
- `TestStoreTestFailuresAsProjectLevelView`
- `TestStoreTestFailuresAsGeneric`
- `TestStoreTestFailuresAsProjectLevelEphemeral`
- `TestStoreTestFailuresAsExceptions`

### Additional Tests

> [!IMPORTANT]
These are new tests introduced into the adapter zone that you should have in your adapter.

| Tests                                                                                                                                                                                     | Issue | PR    | note                                       |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | ----- | ------------------------------------------ |
| `TestIncrementalForeignKeyConstraint`                                                                                                                                                     | #8022 | #8768 | ForeignKey Constraint bug with incremental |
| [`TestCloneSameTargetAndState`](https://github.com/dbt-labs/dbt-core/blob/a3777496b5aad92796327f1452d3c4e6a5d23442/tests/adapter/dbt/tests/adapter/dbt_clone/test_dbt_clone.py#L222-L234) | #8160 | #8638 | `dbt clone`                                |
| `SeedUniqueDelimiterTestBase` `TestSeedWithWrongDelimiter` `TestSeedWithEmptyDelimiter`                                                                                                   | #3990 | #7186 | custom-delimiter for seeds                 |

### Materialized Views and Dynamic Tables Refactor

There's a lot of great, exciting work to share here that will make all of our lives easier. However, we're still digesting the changes into something that we're ready to share.

Feel free to dive in and look around for yourself, but we'll be providing more guidance ideally before November. Our immediate focus is on Coalesce and the dbt-core `1.7.0` release.
