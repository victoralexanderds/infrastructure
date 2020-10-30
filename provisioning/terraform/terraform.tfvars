/*
* Please use your own key
* to track config changes per users
*/

aws_access_key_id = "ACCESS_KEY"
aws_secret_access_key = "SECRET_KEY"
aws_default_region = "ap-southeast-1"
aws_ssh_key_name = "to_jumper"

/*
* Global var
*/

aws_jumper_size = "t3.medium"
aws_cluster_name = "CLUSTER_NAME"
aws_vpc_cidr_block = "10.0.0.0/16"
aws_anywhere_ip = "0.0.0.0/0"
aws_vpn_ip = "VPN_IPADDRESS_CIDR"

aws_cidr_subnets_public = ["10.0.1.0/24","10.0.2.0/24", "10.0.3.0/24"]
aws_cidr_subnets_semi_private = ["10.0.10.0/24","10.0.20.0/24", "10.0.30.0/24"]
aws_cidr_subnets_private = ["10.0.110.0/24","10.0.120.0/24", "10.0.130.0/24"]

default_tags = {
        Orc = "terraform"
        Env = "staging"
}