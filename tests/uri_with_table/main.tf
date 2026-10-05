# test region
provider "aws" {
  region = var.region
}

locals {
  glue_database = "eits_tf_aws_glue_2"

  # The dataset used in this example consists of anonymised data collected by AWS for training 
  data_source = "s3://awsglue-datasets/examples/medicare"
}

# test module
module "glue" {
  source = "./../.."

  # Catalog Database config
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
