# test region
provider "aws" {
  region = var.region
}

locals {
  glue_database = "eits_tf_aws_glue"
}


# test module
module "glue" {
  source = "./../.."

  # Catalog Database config
  database_name        = local.glue_database
  database_description = "Test Glue catalog database using data located in an S3 bucket"

  configure_encryption_settings = true
  create_cloudwatch_logs        = false
  tags                          = var.tags
}