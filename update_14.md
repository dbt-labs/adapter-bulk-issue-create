## Background

The latest version of dbt Core,`dbt-core==1.4.0`, was published on January 25, 2023 ([PyPI](https://pypi.org/project/dbt-core/1.4.0/) | [Github](https://github.com/dbt-labs/dbt-core/releases/tag/v1.4.0)). In fact, a patch, `dbt-core==1.4.1` ([PyPI](https://pypi.org/project/dbt-core/1.4.1/) | [Github](https://github.com/dbt-labs/dbt-core/releases/tag/v1.4.1)), was also released on the same day.

## How to upgrade

https://github.com/dbt-labs/dbt-core/discussions/6624 is an open discussion with more detailed information. If you have questions, please put them there! https://github.com/dbt-labs/dbt-core/issues/6849 is for keeping track of the community's progress on releasing 1.4.0

The above linked guide has more information, but below is a high-level checklist of work that would enable a successful 1.4.0 release of your adapter. 

- [ ] support Python 3.11 (only if your adapter's dependencies allow)
- [ ] Consolidate timestamp functions & macros
- [ ] Replace deprecated exception functions
- [ ] Add support for more tests

## the next minor release: 1.5.0

FYI, `dbt-core==1.5.0` is expected to be released at the end of April. Please plan on allocating a more effort to upgrade support compared to previous minor versions. Expect to hear more in the middle of April.

At a high-level expect much greater adapter test coverage (a very good thing!), and some likely heaving renaming and restructuring as the API-ification of dbt-core is now well underway. See https://github.com/dbt-labs/dbt-core/milestone/82 for more information.