## Background

The latest version of dbt Core,`dbt-core==1.5.0rc1`, was published on April 13, 2023 ([PyPI](https://pypi.org/project/dbt-core/1.5.0rc1/) | [Github](https://github.com/dbt-labs/dbt-core/releases/tag/v1.5.0rc1)).

## How to upgrade

https://github.com/dbt-labs/dbt-core/discussions/7213 is an open discussion with more detailed information. If you have questions, please put them there!

The above linked guide has more information, but below is a high-level checklist of work that would enable a successful 1.5.0 release of your adapter. 

- [ ] Add support Python 3.11 (if you haven't already)
- [ ] Add support for relevant tests (there's a lot of new ones!)
- [ ] Add support model contracts
- [ ] ~~Add support for materialized views~~ (this likely will be bumped to 1.6.0)

## the next minor release: `1.6.0`

FYI, `dbt-core==1.6.0` is expected to be released at the end of July, with a release cut at least two weeks prior.