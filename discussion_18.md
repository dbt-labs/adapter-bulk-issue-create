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

- `1.8.0b2` - second beta - 2024-04-03
- `1.8.0rc1` - release cut - 2024-05-02
- `1.8.0` - final release (ie GA) - 2024-05-09

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

- <https://github.com/dbt-labs/dbt-redshift/compare/v1.7.0...1.8.0b1>
- <https://github.com/dbt-labs/dbt-bigquery/compare/v1.7.0...1.8.0b1>
- <https://github.com/dbt-labs/dbt-snowflake/compare/v1.7.0...1.8.0b1>
- <https://github.com/dbt-labs/dbt-spark/compare/v1.7.0...1.8.0b1>

## TL;DR

TBD

## Breaking changes

TBD

## Changes

### Decoupled Dependency on dbt-core

#### Context

- [dbt Core Roadmap Update 11/23: Adapters & Artifacts](https://github.com/dbt-labs/dbt-core/blob/main/docs/roadmap/2023-11-dbt-tng.md#adapters--artifacts)
- [dbt-core#9171](https://github.com/dbt-labs/dbt-core/discussions/9171)
- [dbt-adapters#87](https://github.com/dbt-labs/dbt-adapters/discussions/87)

##### Excerpt from #9171

> The goals of the work are to do the following:
>
> - Dramatically lower the effort required to maintain an adapter plugin for dbt-core
> - Enable users to install the latest dbt-core version, even if their dbt-* adapter has not had a corresponding release

#### How to implement

Everything you need to know is in [dbt-adapters#87](https://github.com/dbt-labs/dbt-adapters/discussions/87). If you have a question or concern, please ask it there.

### Unit Testing

TBD

#### Tests

For unit testing, there are a handful (3) of functional tests worth implementing as an adapter to ensure both baseline functionality and expected behaviour when mocking inputs with various types:

##### `dbt.tests.adapter.unit_testing.test_types.BaseUnitTestingTypes`

- this test sets up a unit test on a test adapter that mocks out its input with varying data types ([base implementation](https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-tests-adapter/dbt/tests/adapter/unit_testing/test_types.py))
- implementing this should be a matter of overriding the `data_types` fixture ([example](https://github.com/dbt-labs/dbt-bigquery/blob/main/tests/functional/adapter/unit_testing/test_unit_testing.py#L9))
- `data_types` is a list of (`sql_value`, `yaml_value`) where `sql_value` should be a literal in the upstream 'real' input, and `yaml_value` is what the value looks like in yaml when it is being mocked out by the user
- under the hood, the `unit` materialization makes use of `safe_cast` to cast the user-provided yaml value to the expected input type while building fixture CTEs
    - `safe_cast` defers to `cast` if the adapter does not support safe casting to a particular type (e.g. [snowflake's `safe_cast` does not support variant](https://github.com/dbt-labs/dbt-snowflake/blob/main/dbt/include/snowflake/macros/utils/safe_cast.sql#L7))
    - so: the adapter's implementation of `safe_cast` and `cast` may need to be extended as appropriate to support a fuller range of inputs that can be expected from the user in the context of specifying unit test input fixtures.

##### `dbt.tests.adapter.unit_testing.test_case_insensitivity.BaseUnitTestCaseInsensivity`

- this is more of a baseline behaviour test, that ensures input fixtures can specify column names in a case-insensitive manner ([base implementation](https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-tests-adapter/dbt/tests/adapter/unit_testing/test_case_insensitivity.py))
- should be handled by the default implementation and not require anything beyond a passthrough implementation ([example](https://github.com/dbt-labs/dbt-bigquery/pull/1031/files#diff-fa16d6a4b96751c43394815126f09d409c56cc89baff1a089af16c15e55118baR59))
    - unless they are overwriting the unit materialization or [`get_fixture_sql`](https://github.com/dbt-labs/dbt-adapters/blob/35bd3629c390cf87a0e52d999679cc5e33f36c8f/dbt/include/global_project/macros/unit_test_sql/get_fixture_sql.sql#L1), which I'd advise against as those provide the main adapter framework/entrypoints of the unit testing functionality and our 1p implementations have not had to.

##### `dbt.tests.adapter.unit_testing.test_invalid_input.BaseUnitTestInvalidInput`

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
