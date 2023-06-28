
## Overview <!-- markdownlint-disable-line MD041 -->

This discussion is for communicating to adapter maintainers the scope of work needed to make use of the changes in 1.6.0. If you have questions and concerns, please ask them here for posterity.

Please consider this a living document between now and the date of final release. If there's something missing, please comment below!

### release timeline

The below table gives the milestones between up to and including the final release. It will be updated with each subsequent release

| **state**          | **date** | **stage**   | **version** | **release**                                        | Diff to `1.5.0`                                                                     |
| ------------------ | -------- | ----------- | ----------- | -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| :white_check_mark: | Jun 23   | beta        | `1.6.0b6`   | [PyPI](https://pypi.org/project/dbt-core/1.6.0b6/) | [compare `1.6.0b6`](https://github.com/dbt-labs/dbt-core/compare/v1.5.0...v1.6.0b6) |
| :construction:     | Jul 13   | release cut | `1.6.0rc1`  |                                                    |                                                                                     |
| :construction:     | Jul 27   | final       | `1.6.0`     |                                                    |                                                                                     |

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

### :construction: [FEATURE] Materialized Views

#### Context

see #6911

#### How to support

to be completed

#### How to stub elegantly

to be completed

#### What if you do nothing

The default MV DDL statements will be sent to your engine, that will react accordingly - unless you already support MVs, in which case your implementation will superseed this one

### [BtS] Drop support for Py 3.7

#### Context <!-- markdownlint-disable-line MD024 -->

see #7082. As of June 2023, Python 3.7 is now “End of Life” (EOL)

#### How to (remove) support <!-- markdownlint-disable-line MD024 -->

modify the `python_requires` specifier in your packages [`setup.py`](http://setup.py) as well as any other mentions of `3.7` to use `3.8` as the minimum version. Also give yourself the gift of not testing against 3.7 moving forward.

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

You'll likely get security bots flagging vulnerability issues, and users may encounter strange bugs/errors for which there will be no official fix from the Python Software Foundation

### :construction: [FEATURE] `dbt clone`

#### Context <!-- markdownlint-disable-line MD024 -->

tbc

#### How to support <!-- markdownlint-disable-line MD024 -->

tbc

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

tbc

### :construction: [BtS] revamp of `dbt debug`

#### Context <!-- markdownlint-disable-line MD024 -->

tbc

#### How to support <!-- markdownlint-disable-line MD024 -->

tbc

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

tbc

### :construction: [BtS] new arg for `adapter.execute()`

#### Context <!-- markdownlint-disable-line MD024 -->

tbc

#### How to support <!-- markdownlint-disable-line MD024 -->

tbc

#### What if you do nothing <!-- markdownlint-disable-line MD024 -->

tbc


### :construction: [BtS] Adapter zone tests

The first step before starting to the upgrade process is to sure to bump the version of `dbt-tests-adapter`

```md
# latest release as of June 26
dbt-tests-adapter==1.6.0b6
# after release cut
dbt-tests-adapter==1.6.0rc1
# after final release
dbt-tests-adapter~=1.6.0 
```

#### New tests

There are more tests in the adapter-zone test suite ([`tests/adapter/dbt/tests/adapter/`](https://github.com/dbt-labs/dbt-core/tree/main/tests/adapter/dbt/tests/adapter)). Some tests were introduced for new features and others to cover bugs that were fixed for this minor version

Within using the following command
```sh
git diff --unified=0 -G "class Test.*" v1.5.0...v1.6.0b6 tests/adapter/dbt/tests/adapter | grep -E 'class Test.*'
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





