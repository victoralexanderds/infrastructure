variable "aws_access_key_id" {
    description = "AWS Access Key"
}

variable "aws_secret_access_key" {
    description = "AWS Secret Key"
}

variable "aws_default_region" {
    description = "AWS Region"
}

variable "aws_cluster_name" {
    description = "Name of AWS Cluster"
}

variable "aws_vpc_cidr_block" {
    description = "CIDR Block for VPC"
}

variable "aws_cidr_subnets_private" {
    description = "CIDR Blocks for private subnets in Availability Zones"
    type        = "list"
}

variable "aws_cidr_subnets_public" {
    description = "CIDR Blocks for public subnets in Availability Zones"
    type        = "list"
}

variable "aws_cidr_subnets_semi_private" {
    description = "CIDR Blocks for private subnets in Availability zones"
    type        = "list"
}

variable "aws_vpn_ip" {
    description = "VPN IP"
}

variable "aws_anywhere_ip" {
    description = "0.0.0.0/0 blocks"
}

variable "default_tags" {
    description = "Default tags for all resources"
    type        = "map"
}

variable "aws_jumper_size" {
    description = "Instance type for jumper"
}

variable "aws_ssh_key_name" {
    description = "SSH File"
}
