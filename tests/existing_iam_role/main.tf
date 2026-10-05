# test region
provider "aws" {
  region = var.region
}

locals {
  glue_database = "tf_aws_glue_3"

  # The dataset used in this example consists of anonymised data collected by AWS for training 
  data_source = "s3://awsglue-datasets/examples/medicare"
}

# create IAM role to test using an existing role with module
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "AllowGlueAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

module "existing_iam_role" {
  source = "git::https://code.experian.local/scm/EUCES/eits-tf-aws-iam"

  role_name           = format("AWSGlueServiceRole-%s", local.glue_database)
  role_description    = format("Role for AWS Glue, used for database %s", local.glue_database)
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
  policy_name         = format("AWSGlueServiceRole-%s", local.glue_database)
  disable_org_check   = true

  tags = var.tags
}

# test module
module "glue" {
  source = "./../.."

  # test using existing iam role
  create_service_role = false
  service_role_arn    = module.existing_iam_role.role_arn

  # Catalog Database config
  database_name_prefix  = "ti"
  database_name         = local.glue_database
  database_description  = "Test Glue catalog database using data located in an S3 bucket"
  database_location_uri = local.data_source

  # Map of Glue Tables
  tables = {
    medicare = {
      description = "Test Glue Catalog table"
      storage_descriptor = {
        location = local.data_source
      }
    }
  }

  # Map of Glue Crawlers
  crawlers = {
    medicare_test_crawler = {
      schema_change_policy = {
        delete_behavior = "LOG"
        update_behavior = "UPDATE_IN_DATABASE"
      }
      catalog_targets = [
        {
          database_name = local.glue_database
          tables        = ["medicare"]
        }
      ]
    }
  }

  tags = var.tags
}
