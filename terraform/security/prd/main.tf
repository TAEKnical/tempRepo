###################
#   configuration #
###################
provider "aws" {
  region = local.region
}

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }
  }

  backend "s3" {
    bucket = "spoon-iac-kyle"
    key    = "security/prd/seoul.tfstate"
    region = "ap-northeast-2"
  }
}

###################
#  remote_state   #
###################

data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = "spoon-iac-kyle"
    key    = "platforms/prd/seoul.tfstate"
    region = "ap-northeast-2"
  }
}

###################
#     locals      #
###################
locals {
  region      = "ap-northeast-2"
  region_name = "seoul"
  env         = "prd"
  name_prefix = "spoon"
}
###################
#    data block   #
###################

data "aws_caller_identity" "current" {}

###################
#   pod identity  #
###################

module "aws_lb_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  version = "1.7.0"
  name = format("%s-eks-pod-identity-%s", local.name_prefix,"lb_controller")

  attach_aws_lb_controller_policy = true
  associations = {
    lb_controller = {
      cluster_name = data.terraform_remote_state.platform.outputs.spoon_cluster_name
      namespace = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = {
    Environment = local.env
  }
}
