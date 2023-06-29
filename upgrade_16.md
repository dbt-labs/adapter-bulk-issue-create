## Background <!-- markdownlint-disable-line MD041 -->

Minor version `v1.6` is targeted for final release on July 27, 2023. As a maintainer of a dbt adapter, we strongly encourage you to release a corresponding minor version increment to ensure users of your adapter can make use of this new minor version.

## How to upgrade

https://github.com/dbt-labs/dbt-core/discussions/7213 is an open discussion with more detailed information. If you have questions, please put them there!

The above linked guide has more information, but below is a high-level checklist of work that would enable a successful 1.6.0 release of your adapter:

```[tasklist]
### Tasks
- [ ] SUPPORT: materialized views
- [ ] SUPPORT: new `clone` command
- [ ] BEHIND THE SCENES: Drop support for Python 3.7 (if you haven't already)
- [ ] BEHIND THE SCENES: new arg for `adapter.execute()`
- [ ] BEHIND THE SCENES: ensure support for revamped `dbt debug``
- [ ] BEHIND THE SCENES: Add support for new/modified relevant tests
```

## the next minor release: `1.7.0`

FYI, `dbt-core==1.7.0` is expected to be released on October 12, 2023 in time for [Coalesce](https://coalesce.getdbt.com/), the annual analytics engineering conference!