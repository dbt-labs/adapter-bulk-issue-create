## Overview <!-- markdownlint-disable-line MD041 -->

This discussion is for communicating to adapter maintainers the scope of work needed to make use of the changes in 1.7.0. If you have questions and concerns, please ask them here for posterity.

Please consider this a living document between now and the date of final release. If there's something missing, please comment below!

### release timeline

The below table gives the milestones between up to and including the final release. It will be updated with each subsequent release.

- [x] #8261
- [ ] #8262
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

- #8830
- <https://github.com/dbt-labs/dbt-snowflake/pull/800>

### How to get latest changes before `1.7.0rc1` is released

Until the rc releases October 12, the best way to get this suite is via

```zsh
pip install git+https://github.com/dbt-labs/dbt-core.git@main#egg=dbt-core&subdirectory=core
pip install git+https://github.com/dbt-labs/dbt-core.git@main#egg=dbt-tests-adapter&subdirectory=tests/adapter
```

## TL;DR

Excluding the work to consume our refactoring work for materialized views, there should be no breaking changes. Please tell me if I'm wrong, but I believe that things should work by bumping package and dependency versions. I recommend adding tests. Everything below is nice-to-have first steps toward long-term stable interfaces we will develop in future versions.

## Changes

### Catalog fetch performance improvements

#8521 #8648 [dbt-snowflake#758](https://github.com/dbt-labs/dbt-snowflake/pull/758) <!-- markdownlint-disable-line MD018 -->

The performance of parsing projects and generating documentation has always become a bottleneck when one of the two conditions are met:

- Projects grow very large (10,000+ models), or
- Projects are defined within databases and schemas that contain many pre-existing objects

A change for `1.7` addresses the second scenario. The `get_catalog()` macro has always accepted a list of schemas as an argument. All the relations that exist for the given list of schemas are output, regardless of whether or not dbt interacts with this object.

The adapter implementation to solve this problem is three-fold:

1. Introduce a new macro, `get_catalog_relations()` which accepts a list of relations, rather than a list of schemas.
2. A new Adapter class method, `.has_feature()`, to let dbt-core know if the adapter is capable of fetching a catalog from a list of relations. Not all databases support this! See [dbt-snowflake#758#impl.py](https://github.com/dbt-labs/dbt-snowflake/pull/758/files#diff-3b8dfc96ca09cc82325269902a1353fa14e4503308502ba4c64f24e037734bdb) for the change that's needed.
3. Decompose the existing `get_catalog()` macro in order to minimize redundancy with body of `get_catalog_relations()`. This introduces some additional macros:
   1. `get_catalog_tables_sql()` copied straight from pre-existing `get_catalog()` everything you would normally fetch from `INFORMATION_SCHEMA.tables`
   2. `get_catalog_columns_sql()` copied straight from pre-existing `get_catalog()` everything you would normally fetch from `INFORMATION_SCHEMA.columns`
   3. `get_catalog_schemas_where_clause_sql(schemas)` copied straight from pre-existing `get_catalog()`. This uses jinja to loop through the provided schema list and make a big `WHERE schema in schema_list` ` ie joined with `OR`s
   4. `get_catalog_relations_where_clause_sql(relations)` this is likely the only new thing

#### `get_catalog_relations_where_clause_sql`

This macro is effectively an evolution of the old `get_catalog` `WHERE` clause, except now it has the following control flow.

Keep in mind that `relation` in this instance can be a standalone schema, not necessarily an object with a three-part identifier.

```
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

There's a new config for tests, `store_failures_as` which can be `table` or `view`. It overlaps in "interesting" ways with an existing config, `should_store_failures`, which will be deprecated at some point in the future.

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
