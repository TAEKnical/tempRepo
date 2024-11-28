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
    key    = "platforms/prd/seoul.tfstate"
    region = "ap-northeast-2"
  }
}

###################
#   remote state  #
###################
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "spoon-iac-kyle"
    key    = "networks/prd/seoul.tfstate"
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
#       eks       #
###################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "= 20.29.0"

  cluster_name    = format("%s-%s", local.name_prefix, local.env)
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id                   = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.network.outputs.private_subnet_ids["server"]
  control_plane_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids["server"]

  cloudwatch_log_group_retention_in_days = 1

  cluster_addons_timeouts = {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  cluster_addons = {
    coredns = {
      addon_version = "v1.11.3-eksbuild.1",
      most_recent   = false
    }
    kube-proxy = {
      addon_version = "v1.31.2-eksbuild.3",
      most_recent   = false
    }
    vpc-cni = {
      addon_version = "v1.19.0-eksbuild.1",
      most_recent   = false
    }
    # aws-ebs-csi-driver = {
    #   addon_version = "v1.37.0-eksbuild.1",
    #   most_recent   = false
    # }
    eks-pod-identity-agent = {
      addon_version = "v1.3.4-eksbuild.1",
      most_recent   = false
    }
  }

  eks_managed_node_groups = {
    spoon-240521 = {
      capacity_type = "ON_DEMAND"
      timeouts = {
        create = "5m"
        update = "5m"
        delete = "5m"
      }
      enable_bootstrap_user_data = true
      name                       = format("%s", local.name_prefix)
      use_name_prefix            = false
      ami_type                   = "AL2023_x86_64_STANDARD"
      instance_types             = ["t3.micro"]
      capacity_type              = "SPOT"
      block_device_mappings = {
        xvdb = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      iam_role_use_name_prefix = false
      create_iam_role          = true
      iam_role_additional_policies = {
        "AmazonSSMManagedInstanceCore" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        # "AmazonEBSCSIDriverPolicy"     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      tag_specifications                     = ["instance", "network-interface", "volume"]
      ami_id                                 = "ami-06e7ede5954a131ae" #amazon-eks-node-al2023-x86_64-standard-1.31-v20241121
      launch_template_tags                   = merge({ Name = format("%s-eks-node", local.name_prefix) })
      launch_template_use_name_prefix        = false
      update_launch_template_default_version = true

      max_size     = 4
      desired_size = 4
      min_size     = 1
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = local.env
    Terraform   = "true"
  }
}
