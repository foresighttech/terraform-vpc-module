variable "availability_zone_count" {
    type = number
    default = 2
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "namespace_root_domain" {}

variable "env" {}

variable "tgw_id" {}