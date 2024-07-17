terraform {
    required_version = ">= 1.2.0"
  
    backend "s3" {
        bucket         = "dapp-terraform-state"
        key            = "tf-infra/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "dappTFState"
        encrypt        = true
    }

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

module "ecrRepo" {
    source        = "./modules/ecr"
    ecr_repo_name = "dapp-ecr-repo"
}