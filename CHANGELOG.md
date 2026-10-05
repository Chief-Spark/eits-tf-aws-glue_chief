# RELEASE NOTES

## 1.5.1 - 14th September 2026

- Updated confluence document links

## 1.5.0 - 6th May 2026

- Added `cloudwatch_log_group_name` variable to allow per-database CloudWatch log group naming

## 1.4.0 - 27th April 2026

- Added `database_name_prefix` variable
- Bumped pre-commit to version `1.4.0`

## 1.3.5 - 22nd December 2025

- Add `var.tables.partition_keys.parameters` argument
- Fix `data.aws_region.current.name` deprecation
- Update required AWS provider to `6.11` to enable new features
- Updated `eits-tf-aws-iam` module to version `1.9.3`
- Updated `eits-tf-aws-cloudwatch-logs` module to version `2.6.1`

## 1.3.4 - 15th December 2025

- Bugfix: Glue database name check to include valid `-` character in the regex
- Updated minimum required Terraform version to support submodules

## 1.3.3 - 10th December 2025

- Updated `eits-tf-aws-iam` module to version `1.9.2`
- Updated `eits-tf-aws-cloudwatch-logs` module to version `2.6.0`

## 1.3.2 - 13th September 2025

 - Updated `eits-tf-aws-iam` pinned version to `1.9.1`

## 1.3.1 - 23rd April 2025

- Updated Cloudwatch Logs module to bugfix version 2.5.1

## 1.3.0 - 7th April 2025

- Renamed `warnings.tf` to `checks.tf`
- Converted warnings to check blocks
- Updated IAM module dependency to 1.7.1
- Updated Cloudwatch Logs dependency version to 2.5.0
- Changed to use `ce-common` module instead of `vars`
- Updated module dependecies used in tests (IAM, KMS and S3)
- Removed `tlkamp/validation` provider

## 1.2.1 - 31th March 2025

- Updated depended IAM module version 1.5.0
- Updated review date

## 1.2.0 - 28th Feburary 2025

- New flag `configure_encryption_settings` to set up encryption for glue at the AWS account level.  Only needs to be done once per account to set encryption account-wide.  Assorted other variables are only needed when setting this flag to `true`.
- Added flag `create_cloudwatch_logs` for logging to Cloudwatch, it defaults to `true`, but can be disabled if not needed.  Utilizes EITS Cloudwatch logs module for log group creation.
- Added warning if `database_description` is left empty.

## 1.1.0 - 3rd September 2024

- Allow existing IAM role to be used with the addition of the following arguments:
  - `create_service_role`
  - `service_role_arn`
- Add new 'tests' directory to test an existing IAM role.

## 1.0.0 - 15th August 2024

- Initial release
