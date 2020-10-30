/*
* Lock terraform state to avoid state conflict
* require one bucket and one dynamodb
*/
terraform {
    backend "s3" {
        bucket = "terraform-state"
        key = "tfstate"
        region = "ap-southeast-1"
        encrypt = true
        dynamodb_table = "tf-lock"
    }
}

provider "aws" {
    access_key = "${var.aws_access_key_id}"
    secret_key = "${var.aws_secret_access_key}"
    region     = "${var.aws_default_region}"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "centos" {
    most_recent = true

    filter {
        name   = "name"
        values = ["chef-highperf-centos7-201910072320"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["446539779517"]
}

module "vpc" {
    source = "./modules/vpc"

    aws_cluster_name                    = "${var.aws_cluster_name}"
    aws_vpc_cidr_block                  = "${var.aws_vpc_cidr_block}"
    aws_avail_zones                     = "${slice(data.aws_availability_zones.available.names, 0, 3)}"
    aws_cidr_subnets_private            = "${var.aws_cidr_subnets_private}"
    aws_cidr_subnets_semi_private       = "${var.aws_cidr_subnets_semi_private}"
    aws_cidr_subnets_public             = "${var.aws_cidr_subnets_public}"
    aws_anywhere_ip                     = "${var.aws_anywhere_ip}"
    aws_vpn_ip                          = "${var.aws_vpn_ip}"
    default_tags                        = "${var.default_tags}"
}

resource "aws_iam_role" "kube" {
    name = "${var.aws_cluster_name}-iam"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "ec2.amazonaws.com"
        }
    }]
}
EOF
}

resource "aws_iam_role_policy" "kube" {
    name = "${var.aws_cluster_name}-iam-policy"
    role = "${aws_iam_role.kube.id}"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ec2:*"],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": ["elasticloadbalancing:*"],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": ["route53:*"],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "kube" {
    name = "${var.aws_cluster_name}_kube_profile"
    role = "${aws_iam_role.kube.name}"
}

resource "aws_instance" "jumper" {
    ami             = "${data.aws_ami.centos.id}"
    instance_type   = "${var.aws_jumper_size}"

    availability_zone = "${element(
        slice(data.aws_availability_zones.available.names, 0, 3),
        count.index,
    )}"

    associate_public_ip_address = true
    subnet_id   = "${element(module.vpc.aws_subnet_ids_public,count.index)}"
    vpc_security_group_ids = ["${module.vpc.aws_security_group_base}"]
    key_name = "${var.aws_ssh_key_name}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-jumper",
        "Cluster", "${var.aws_cluster_name}",
        "Role", "jumper-${var.aws_cluster_name}-${count.index}"
    ))}"
}
