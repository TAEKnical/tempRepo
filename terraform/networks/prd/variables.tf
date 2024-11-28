variable "env" {
    description = "infra environment (dev, stg, prd)"
    type = string
    default = "dev"
}

variable "subnets" {
    description = "subnet block"
    default = {
        public_subnets = {
            common = {
                ap-northeast-2a = ["10.21.0.0/24"]
                ap-northeast-2b = ["10.21.1.0/24"]
            }
        },
        private_subnets = {
            server ={
                ap-northeast-2a = ["10.21.32.0/24"]
                ap-northeast-2b = ["10.21.33.0/24"]
            }
        }
    }
}
