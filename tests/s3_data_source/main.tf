# test region
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  account_id              = data.aws_caller_identity.current.account_id
  glue_database           = "eits_tf_aws_glue"
  glue_table              = local.source_bucket_name
  file_path               = "src"
  data_file               = "sample_data.csv"
  script_template         = "glue_code.tftpl"
  script_name             = "glue_code.py"
  source_bucket_name      = "${local.account_id}-eits-tf-aws-glue-source"
  destination_bucket_name = "${local.account_id}-eits-tf-aws-glue-destination"
}

# create kms key for buckets
data "aws_iam_policy_document" "glue_role_access" {
  statement {
    sid    = "AllowGlueServiceRole"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${local.account_id}:role/BURoleForAWSGlueServiceRole-${local.glue_database}"]
    }
  }
}

module "bucket_kms_key" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-kms.git?ref=1.8.0"

  prefix       = "eits-tf-aws-glue"
  description  = "KMS key to encrypt S3 buckets for Glue testing"
  policy       = data.aws_iam_policy_document.glue_role_access.json
  key_owners   = [data.aws_iam_session_context.current.issuer_arn]
  key_services = ["s3"]

  tags = var.tags
}

# create data source bucket
# you may need to delete all versions of objects in buckets before deleting the buckets
module "source_bucket" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-s3.git?ref=2.11.0"

  bucket_name             = local.source_bucket_name
  force_destroy           = true
  sse_algorithm           = "aws:kms"
  kms_key_arn             = module.bucket_kms_key.key_arn
  disable_default_alarms  = true
  disable_source_ip_check = true

  tags = var.tags
}

# upload example data
resource "aws_s3_object" "example_data" {
  bucket        = module.source_bucket.s3_bucket_id
  key           = local.data_file
  force_destroy = true
  source        = "${local.file_path}/${local.data_file}"
}

# upload job script
resource "aws_s3_object" "job_script" {
  bucket        = module.source_bucket.s3_bucket_id
  key           = local.script_name
  force_destroy = true
  content = templatefile("${local.file_path}/${local.script_template}", {
    glue_database           = local.glue_database
    glue_table              = local.glue_table
    destination_bucket_name = local.destination_bucket_name
  })
}

# create results bucket
module "destination_bucket" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-s3.git?ref=2.11.0"

  bucket_name             = local.destination_bucket_name
  force_destroy           = true
  sse_algorithm           = "aws:kms"
  kms_key_arn             = module.bucket_kms_key.key_arn
  disable_default_alarms  = true
  disable_source_ip_check = true

  tags = var.tags
}

# policy to grant glue access to buckets and kms keys
data "aws_iam_policy_document" "glue_role_policy" {
  statement {
    sid    = "AllowGlueAccessToKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [module.bucket_kms_key.key_arn]
  }

  statement {
    sid    = "AllowGlueReadAccessToS3"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      module.source_bucket.s3_bucket_arn,
      "${module.source_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "AllowGlueWriteAccessToS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.destination_bucket.s3_bucket_arn,
      "${module.destination_bucket.s3_bucket_arn}/*"
    ]
  }
}

# test module
module "glue" {
  source = "./../.."

  # Catalog Database config
  database_name        = local.glue_database
  database_description = "Test Glue catalog database using data located in an S3 bucket"

  # IAM role config
  service_role_policy_documents = [data.aws_iam_policy_document.glue_role_policy.json]

  # Map of Glue Crawlers
  crawlers = {
    sample_data_test_crawler = {
      schema_change_policy = {
        delete_behavior = "DELETE_FROM_DATABASE"
        update_behavior = "UPDATE_IN_DATABASE"
      }
      s3_targets = [
        {
          path       = format("s3://%s", module.source_bucket.s3_bucket_id)
          exclusions = ["*.py"]
        }
      ]
    }
  }

  # Map of Glue Jobs
  jobs = {
    sample_data_test_job = {
      command = {
        script_location = format("s3://%s/%s", module.source_bucket.s3_bucket_id, local.script_name)
        python_version  = 3
      }
      worker_type       = "G.1X"
      number_of_workers = 5
      glue_version      = "4.0"
      timeout           = 10
      execution_property = {
        max_concurrent_runs = 1
      }
    }
  }

  tags = var.tags
}