terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

module "tfState" {
  source      = "./modules/tf-state"
  bucket_name = "dapp-terraform-state"
  table_name  = "dappTFState"
}