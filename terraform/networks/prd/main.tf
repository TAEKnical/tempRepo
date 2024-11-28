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
    key    = "networks/prd/seoul.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  region      = "ap-northeast-2"
  region_name = "seoul"
  env         = "prd"
  name_prefix = "spoon"
  cluster_name = format("%s-%s",local.name_prefix, local.env)

  vpc_cidr_block = "10.21.0.0/16"
  azs = ["ap-northeast-2a", "ap-northeast-2b"]

  public_subnets = flatten([
    for name, subnets in var.subnets.public_subnets : [
      for az, cidrs in subnets : [
        for idx, cidr in cidrs : {
          name = name
          az   = az
          idx  = idx
          cidr = cidr
          layer = "publlic"
  }]]])

  private_subnets = flatten([
    for name, subnets in var.subnets.private_subnets : [
      for az, cidrs in subnets : [
        for idx, cidr in cidrs : {
          name = name
          az   = az
          idx  = idx
          cidr = cidr
          layer = "private"
  }]]])
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = local.cluster_name
  cidr = local.vpc_cidr_block
  enable_dhcp_options              = true
  enable_dns_hostnames = true
  create_egress_only_igw = true

  azs                 = local.azs
  public_subnets = [
    for subnet in local.public_subnets :
    "${subnet.cidr}"
  ]
  private_subnets = [
    for subnet in local.private_subnets :
    "${subnet.cidr}"
  ]
 
  
  enable_nat_gateway = true
  single_nat_gateway = false

  create_multiple_public_route_tables = true
  public_subnet_names = [
    for subnet in local.public_subnets :
    format("%s-%s-%s", local.name_prefix, local.env, "${subnet.layer}-${subnet.name}-${substr(subnet.az, -1, 1)}")
  ]
  private_subnet_names = [
    for subnet in local.private_subnets :
    format("%s-%s-%s", local.name_prefix, local.env, "${subnet.layer}-${subnet.name}-${substr(subnet.az, -1, 1)}")
  ]

  #elb subnet따로 있으면 분리
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }


  tags = {
    Terraform = "true"
    Environment = local.env
  }
}
