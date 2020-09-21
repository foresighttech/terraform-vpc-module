variable "availability_zone_count" {
    type = number
    default = 2
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "ha_nat" {
    type = bool
    default = true
}

variable "namespace_root_domain" {}

variable "env" {}