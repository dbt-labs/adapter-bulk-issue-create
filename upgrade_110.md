## Background <!-- markdownlint-disable-line MD041 -->

Minor version `v1.10` was released on June 16, 2024.

If your adapter supports dbt-Core 1.8 or later, it is not a requirement that you ship support for `1.10` as it contains only backwards-compatible changes, predominately new features.

However you will need ship a new minor version if want your users to be able to make use of the new features.

Also note that end users are not likely to appreciate that the minor version of an adapter no longer has to exactly match. So you may get users asking for a new release.

## Features

See the below-linked guide for more detail but at a high-level, `1.10` predominately contains:

1. Iceberg catalog integration support
2. Sample mode
3. Deprecation warnings

## How to upgrade

https://github.com/dbt-labs/dbt-core/discussions/11864 is an open discussion with more detailed information. If you have questions, please put them there!  <!-- markdownlint-disable-line MD034 -->
