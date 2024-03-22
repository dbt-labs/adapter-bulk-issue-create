## Overview <!-- markdownlint-disable-line MD041 -->

This discussion is for communicating to adapter maintainers the scope of work needed to make use of the changes coming via dbt-core 1.8.0. If you have questions and concerns, please ask them here for posterity.

Please consider this a living document between now and the date of final release. If there's something missing, please comment below!

<details><summary>

### Loom video overview (12 min)

</summary>

TBD

</details>

### release timeline

The below table gives the milestones between up to and including the final release. It will be updated with each subsequent release.

- [x] #9780
- [ ] #9781
- [ ] #9782
- [ ] #9783

<details><summary>

### prior maintainer upgrade guides

</summary>

- #8307
- #7958
- #7213
- #6624
- #6011
- #5468

</details>

### Example Diffs

- <https://github.com/dbt-labs/dbt-redshift/compare/v1.7.0...v1.8.0b1>
- <https://github.com/dbt-labs/dbt-bigquery/compare/v1.7.0...v1.8.0b1>
- <https://github.com/dbt-labs/dbt-snowflake/compare/v1.7.0...v1.8.0b1>
- <https://github.com/dbt-labs/dbt-spark/compare/v1.7.0...v1.8.0b1>

## TL;DR

This upgrade is a big deal, and should be the last time in a while that dbt Labs asks maintainers for this amount of work. There's two logical pieces of work here, that, in theory, aren't especially complex:

- decoupling dependency on dbt-core
- supporting the new unit testing feature for end users

## Decoupled Dependency on dbt-core

### Context

- [dbt Core Roadmap Update 11/23: Adapters & Artifacts](https://github.com/dbt-labs/dbt-core/blob/main/docs/roadmap/2023-11-dbt-tng.md#adapters--artifacts)
- [dbt-core#9171](https://github.com/dbt-labs/dbt-core/discussions/9171)
- [dbt-adapters#87](https://github.com/dbt-labs/dbt-adapters/discussions/87)

#### Excerpt from #9171

> The goals of the work are to do the following:
>
> - Dramatically lower the effort required to maintain an adapter plugin for dbt-core
> - Enable users to install the latest dbt-core version, even if their dbt-* adapter has not had a corresponding release

### How to implement

Everything you need to know is in [dbt-adapters#87](https://github.com/dbt-labs/dbt-adapters/discussions/87). If you have a question or concern, please ask it there.

## Unit Testing

Unit testing is a long-awaited feature that is finally coming to dbt. It is a powerful feature that will allow users to test their models in isolation from the rest of their project. This should not require a great deal of work on the part of the adapter maintainer, but, more importantly, how dbt is used changes, so it's important that we have test coverage for these new scenarios.s

### support for `--empty` flag to enable "dry run" mode

- [dbt-core#8980](https://github.com/dbt-labs/dbt-core/issues/8980): original issue
- [dbt-core#8971](https://github.com/dbt-labs/dbt-core/pull/8971): Core PR
- [dbt-redshift#666](https://github.com/dbt-labs/dbt-redshift/issues/666): Example implementation

#### How to implement `--empty` support

[dbt-core#8971](https://github.com/dbt-labs/dbt-core/pull/8971) added a new BaseRelation method: [`render_limited()`](https://github.com/dbt-labs/dbt-core/blob/7967be7bb373a3c737196bc0ebbe31ef6f4ed354/core/dbt/adapters/base/relation.py#L198-L205). Effectively, this method will wrap a model's `SELECT` statement into a subquery

```sql
(select * from {rendered} limit {self.limit}) _dbt_limit_subq

-- if limit is 0 (`where false` for cost saving)
(select * from {rendered} where false limit 0) _dbt_limit_subq
```

If your data platform supports `LIMIT` clauses, you have no work to do. However, some SQL dialects (e.g. T-SQL) do not support `LIMIT` clauses. In this case, you will need to implement `render_limited()` for your adapter.

#### `--empty` Tests

`dbt.tests.adapter.empty.test_empty.BaseTestEmpty`

### macros `CAST` and `SAFE_CAST` support

dbt does a vast amount of type casting behind the scenes such as:

- data warehouse data types <> Python
- `agate` (our current csv reader) <> Python
- `YAML` <> Python

In the case of unit testing, we needed to extend further the `yaml`<>`python` casting to allow for more specific definition of mock data.

theoretically this should be a no-op for most adapters, but it's worth checking to make sure that the `CAST` and `SAFE_CAST` macros are supported in your adapter. For example, dbt-spark now has a `safe_cast` that it did not before ([dbt-spark#files](https://github.com/dbt-labs/dbt-spark/pull/976/files)).

#### Tests within `dbt.tests.adapter.unit_testing`

For unit testing, there are a handful (3) of functional tests worth implementing as an adapter to ensure both baseline functionality and expected behavior when mocking inputs with various types:

##### `test_types.BaseUnitTestingTypes`

- this test sets up a unit test on a test adapter that mocks out its input with varying data types ([base implementation](https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-tests-adapter/dbt/tests/adapter/unit_testing/test_types.py))
- implementing this should be a matter of overriding the `data_types` fixture ([example](https://github.com/dbt-labs/dbt-bigquery/blob/main/tests/functional/adapter/unit_testing/test_unit_testing.py#L9))
- `data_types` is a list of (`sql_value`, `yaml_value`) where `sql_value` should be a literal in the upstream 'real' input, and `yaml_value` is what the value looks like in yaml when it is being mocked out by the user
- under the hood, the `unit` materialization makes use of `safe_cast` to cast the user-provided yaml value to the expected input type while building fixture CTEs
    - `safe_cast` defers to `cast` if the adapter does not support safe casting to a particular type (e.g. [snowflake's `safe_cast` does not support variant](https://github.com/dbt-labs/dbt-snowflake/blob/main/dbt/include/snowflake/macros/utils/safe_cast.sql#L7))
    - so: the adapter's implementation of `safe_cast` and `cast` may need to be extended as appropriate to support a fuller range of inputs that can be expected from the user in the context of specifying unit test input fixtures.

##### `test_case_insensitivity.BaseUnitTestCaseInsensivity`

- this is more of a baseline behavior test, that ensures input fixtures can specify column names in a case-insensitive manner ([base implementation](https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-tests-adapter/dbt/tests/adapter/unit_testing/test_case_insensitivity.py))
- should be handled by the default implementation and not require anything beyond a passthrough implementation ([example](https://github.com/dbt-labs/dbt-bigquery/pull/1031/files#diff-fa16d6a4b96751c43394815126f09d409c56cc89baff1a089af16c15e55118baR59))
    - unless they are overwriting the unit materialization or [`get_fixture_sql`](https://github.com/dbt-labs/dbt-adapters/blob/35bd3629c390cf87a0e52d999679cc5e33f36c8f/dbt/include/global_project/macros/unit_test_sql/get_fixture_sql.sql#L1), which I'd advise against as those provide the main adapter framework/entrypoints of the unit testing functionality and our 1p implementations have not had to.

##### `test_invalid_input.BaseUnitTestInvalidInput`

- another baseline test that ensures the appropriate error & messaging is raised by the adapter if a user specifies an invalid column name in an input fixture ([base implementation](https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-tests-adapter/dbt/tests/adapter/unit_testing/test_invalid_input.py))
- should be handled by the default implementation and not require anything beyond a passthrough implementation ([example](https://github.com/dbt-labs/dbt-bigquery/pull/1031/files#diff-fa16d6a4b96751c43394815126f09d409c56cc89baff1a089af16c15e55118baR63))
    - unless they are overwriting the `format_row` macro which is what [provides this functionality in the default implementation](https://github.com/dbt-labs/dbt-adapters/blob/35bd3629c390cf87a0e52d999679cc5e33f36c8f/dbt/include/global_project/macros/unit_test_sql/get_fixture_sql.sql#L75-L78).

### Additional Tests

> [!IMPORTANT]
These are new tests introduced into the adapter zone that you should have in your adapter.

TBD

### Materialized Views Refactor

When the `1.7` upgrade guide was originally published (October 2023), the "Materialized Views Refactor" was stubbed out. In December it was more fully fleshed out.

If your warehouse supports materialized views, you should check it out. Even if you don't the changes implemented represent a vision of the future for how materializations are handled in dbt.
