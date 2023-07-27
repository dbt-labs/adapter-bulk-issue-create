
## Overview <!-- markdownlint-disable-line MD041 -->

This discussion is for communicating to adapter maintainers the scope of work needed to make use of the changes in 1.6.0. If you have questions and concerns, please ask them here for posterity.

Please consider this a living document between now and the date of final release. If there's something missing, please comment below!

### release timeline

The below table gives the milestones between up to and including the final release. It will be updated with each subsequent release

| **state**          | **date** | **stage**    | **version**    | **release**                                        | Diff to `1.5.0`                                                                     |
| ------------------ | -------- | ------------ | -------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| :white_check_mark: | Jun 23   | beta         | `1.6.0b6`      | [PyPI](https://pypi.org/project/dbt-core/1.6.0b6/) | [compare `1.6.0b6`](https://github.com/dbt-labs/dbt-core/compare/v1.5.0...v1.6.0b6) |
| :construction:     | Jul 13   | release cut  | `1.6.0rc1`     |                                                    |                                                                                     |
| :construction:     | Jul 27   | final        | `1.6.0`        |                                                    |                                                                                     |
| :construction:     | Jul 31   | in dbt Cloud | `1.6 (latest)` |                                                    |                                                                                     |

### prior maintainer upgrade versions

- #7213
- #6624
- #6011
- #5468

## Changes

as an adapter maintainer, there's three options for new features in dbt Core:

1. support the change
2. "stub" the feature as in add in code to let users know that the feature is "not supported"
3. do nothing. if an adapter maintainer does nothing, then, if an end user tries to use that feature, the default implementation of dbt-core will be made which will result in SQL being generated and sent to the underlying data platform, which will likely make the platform throw an error.

### Example diffs from dbt Labs-owned adapters

Below gives the changes as of the latest beta release (as of June 26). The canonical way to check the diff of a minor version is `compare/v1.4.0...1.5.latest`, but the `1.5.latest` branch is not created until the `rc` is released.

- <https://github.com/dbt-labs/dbt-redshift/compare/v1.5.0...v1.6.0b4>
- <https://github.com/dbt-labs/dbt-bigquery/compare/v1.5.0...v1.6.0b4>
- <https://github.com/dbt-labs/dbt-snowflake/compare/v1.5.0...v1.6.0b3>
- <https://github.com/dbt-labs/dbt-spark/compare/v1.5.0...v1.6.0b3>

### Areas to consider

note:  :construction: means that this guide is not yet complete and "BtS" is short for Behind the Scenes, ie not a user-facing change

<details>

<summary> [FEATURE] Materialized Views</summary>

#### Context

original issue: https://github.com/dbt-labs/dbt-core/issues/6911

#### How to support

a more comprehensive guide is still forthcoming, but for now, please refer to the following PRs to learn more

relevant PRs:
- https://github.com/dbt-labs/dbt-core/pull/7334/
- https://github.com/dbt-labs/dbt-redshift/pull/387
- :construction: https://github.com/dbt-labs/dbt-snowflake/pull/659/
- :construction: https://github.com/dbt-labs/dbt-bigquery/issues/672

Of particular interested would are:
1. the default (global) implementation for materialized views ([`core/dbt/include/global_project/macros/materializations/models/materialized_view/materialized_view.sql`](https://github.com/dbt-labs/dbt-core/blob/main/core/dbt/include/global_project/macros/materializations/models/materialized_view/materialized_view.sql))
2. [relation_configs/README.md](https://github.com/dbt-labs/dbt-core/pull/7239/files#diff-0f50b6142889a932591ab8dd774fac2a0dc075f2d7dfb8fbe50bb12fd02f1d64) which describes an extra config set related to MVs that likely will be embraced for all relation configuration in future minor versions
3. how postgres tweaks/overrides specific macros corresponding to the default/global implementation ([`plugins/postgres/dbt/include/postgres/macros/materializations/materialized_view.sql`](https://github.com/dbt-labs/dbt-core/blob/main/plugins/postgres/dbt/include/postgres/macros/materializations/materialized_view.sql)))
   1. `postgres__get_alter_materialized_view_as_sql`
   2. `postgres__get_create_materialized_view_as_sql`
   3. `postgres__get_replace_materialized_view_as_sql`
   4. `postgres__get_materialized_view_configuration_changes`
   5. `postgres__refresh_materialized_view`
   6. `postgres__update_indexes_on_materialized_view`
   7. `postgres__describe_materialized_view`
4. how dbt-snowflake implements dynamic tables (see https://github.com/dbt-labs/dbt-snowflake/pull/659/)
   1. [`materialization: dynamic_table`](https://github.com/dbt-labs/dbt-snowflake/blob/aa7bfd757de10d4beb0e55f729791d815107cfe8/dbt/include/snowflake/macros/materializations/dynamic_table/materialization.sql)
   2. `snowflake__create_table_as` (add a `is_dynamic` conditional)
   3. `snowflake__drop_relation_sql` (add a `is_dynamic` conditional)
   4. `snowflake__alter_dynamic_table_sql`
   5. `snowflake__create_dynamic_table_sql`
   6. `snowflake__describe_dynamic_table`
   7. `snowflake__drop_dynamic_table_sql`
   8. `snowflake__refresh_dynamic_table_sql`
   9. `snowflake__replace_dynamic_table_sql`
   10. `snowflake__alter_dynamic_table_sql_with_on_configuration_change_option`
   11. `dynamic_table_execute_no_op`
   12. `dynamic_table_execute_build_sql`

#### How to stub elegantly

to be completed

#### What if you do nothing

The default MV DDL statements will be sent to your engine, that will react accordingly - unless you already support MVs, in which case your implementation will superseed this one

</details>

<details>

<summary>[BtS] Drop support for Py 3.7</summary>

#### Context <!-- markdownlint-disable-line MD024 -->

see #7082. As of June 2023, Python 3.7 is now “End of Life” (EOL)

#### How to (remove) support <!-- markdownlint-disable-line MD024 -->

modify the `python_requires` specifier in your packages [`setup.py`](http://setup.py) as well as any other mentions of `3.7` to use `3.8` as the minimum version. Also give yourself the gift of not testing against 3.7 moving forward.

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

You'll likely get security bots flagging vulnerability issues, and users may encounter strange bugs/errors for which there will be no official fix from the Python Software Foundation

</details>

<details>

<summary> [FEATURE] `dbt clone`</summary>

#### Context <!-- markdownlint-disable-line MD024 -->

`dbt clone` ([docs page](https://docs.getdbt.com/reference/commands/clone))

#### How to support <!-- markdownlint-disable-line MD024 -->

If your data platform supports the capability to clone, then there are two macros to override:

- `can_clone_table()`, and
- `create_or_replace_clone()`

See below for the versions introduced to the BigQuery adapter via [dbt-bigquery#784](https://github.com/dbt-labs/dbt-bigquery/pull/784).

```sql
{% macro bigquery__can_clone_table() %}
    {{ return(True) }}
{% endmacro %}

{% macro bigquery__create_or_replace_clone(this_relation, defer_relation) %}
    create or replace
      table {{ this_relation }}
      clone {{ defer_relation }}
{% endmacro %}
```

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

tbc

</details>

<details>

<summary>[BtS] revamp of `dbt debug`</summary>

#### Context <!-- markdownlint-disable-line MD024 -->

See [dbt-core#7104](https://github.com/dbt-labs/dbt-core/issues/7104)

#### How to support <!-- markdownlint-disable-line MD024 -->

There is a new Adapter method, `.debug_query()`, whose default value is `select 1 as id`. If this does not work on your supported data platform, you may override it.

Also, an existing test was modified to test the new command-line flag functionality.

`TestDebugPostgres` ([sauce](https://github.com/dbt-labs/dbt-core/blob/adc4dbc4d6a2e4423a0e5159acc0c2f5d94f060f/tests/adapter/dbt/tests/adapter/dbt_debug/test_dbt_debug.py#L49C7-L82))

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

no end-user impact

</details>

<details>

<summary> [BtS] new arg for `adapter.execute()`</summary>


#### Context <!-- markdownlint-disable-line MD024 -->

To more fully support `dbt show`, we needed the ability to fetch only the rows that users specified via command-line flag. The behavior shipped in `1.5` would needlessly fetch the entire user-supplied query, then after return the specified number of rows.

The new argument is called `limit`
([source](https://github.com/dbt-labs/dbt-core/blob/ff5cb7ba51b4133f836d8d45ee8bb52f01ff4b4e/core/dbt/adapters/sql/connections.py#L143C72-L143C77))



#### How to support <!-- markdownlint-disable-line MD024 -->

If your adapter over-rides SQLConnectionManager.execute(), you must include `limit` in it's function signature

Additionally, if your adapter overrides dbt-core's [`BaseAdapter.execute()`](https://github.com/dbt-labs/dbt-core/blob/main/core/dbt/adapters/base/impl.py#L275-L290), you must also update that method to include the `limit` parameter.

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

Things likely won't work for end users

</details>

<details>

<summary>[BtS] Adapter zone tests</summary>


The first step before starting to the upgrade process is to sure to bump the version of `dbt-tests-adapter`

```md
# after release cut
dbt-tests-adapter==1.6.0rc1
# after final release
dbt-tests-adapter~=1.6.0 
```

#### New tests

There are more tests in the adapter-zone test suite ([`tests/adapter/dbt/tests/adapter/`](https://github.com/dbt-labs/dbt-core/tree/main/tests/adapter/dbt/tests/adapter)). Some tests were introduced for new features and others to cover bugs that were fixed for this minor version

Within using the following command
```sh
git diff --unified=0 -G "class Test.*" v1.5.0...v1.6.0rc1 tests/adapter/dbt/tests/adapter | grep -E 'class Test.*'
```

below is a non-exhaustive list of some of the newly introduced tests

- `TestIncrementalConstraintsRollback`
- `TestTableContractSqlHeader`
- `TestIncrementalContractSqlHeader`
- `TestModelConstraintsRuntimeEnforcement`
- `TestConstraintQuotedColumn`
- `TestEquals`
- `TestMixedNullCompare`
- `TestNullCompare`
- `TestPostgresCloneNotPossible`
- `TestValidateSqlMethod`

</details>
