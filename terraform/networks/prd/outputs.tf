output "private_subnet_ids" {
    value = {
        for k, v in module.vpc.private_subnet_objects:
            split("-", v.tags.Name)[3] => v.id...
    }
}

output "vpc_cidr_block" {
    value = module.vpc.vpc_cidr_block
}

output "vpc_id" {
    value = module.vpc.vpc_id
}
