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

TBD

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

TBD

### Additional Tests

> [!IMPORTANT]
These are new tests introduced into the adapter zone that you should have in your adapter.

TBD

### Materialized Views Refactor

When the `1.7` upgrade guide was originally published (October 2023), the "Materialized Views Refactor" was stubbed out. In December it was more fully fleshed out.

If your warehouse supports materialized views, you should check it out. Even if you don't the changes implemented represent a vision of the future for how materializations are handled in dbt.
