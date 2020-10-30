resource "aws_vpc" "cluster-vpc" {
    cidr_block = "${var.aws_vpc_cidr_block}"

    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}"
    ))}"
}

resource "aws_eip" "cluster-nat-eip" {
    count = "${length(var.aws_cidr_subnets_public)}"
    vpc   = true
}

resource "aws_internet_gateway" "cluster-vpc-internetgw" {
    vpc_id = "${aws_vpc.cluster-vpc.id}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-internetgw"
    ))}"
}

resource "aws_subnet" "cluster-vpc-subnets-public" {
    vpc_id            = "${aws_vpc.cluster-vpc.id}"
    count             = "${length(var.aws_avail_zones)}"
    availability_zone = "${element(var.aws_avail_zones, count.index)}"
    cidr_block        = "${element(var.aws_cidr_subnets_public, count.index)}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-${element(var.aws_avail_zones, count.index)}-public",
    ))}"
}

resource "aws_nat_gateway" "cluster-nat-gateway" {
    count         = "${length(var.aws_cidr_subnets_public)}"
    allocation_id = "${element(aws_eip.cluster-nat-eip.*.id, count.index)}"
    subnet_id     = "${element(aws_subnet.cluster-vpc-subnets-public.*.id, count.index)}"
}

resource "aws_subnet" "cluster-vpc-subnets-semi-private" {
    vpc_id            = "${aws_vpc.cluster-vpc.id}"
    count             = "${length(var.aws_avail_zones)}"
    availability_zone = "${element(var.aws_avail_zones, count.index)}"
    cidr_block        = "${element(var.aws_cidr_subnets_semi_private, count.index)}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-${element(var.aws_avail_zones, count.index)}-semi-private",
    ))}"
}

resource "aws_subnet" "cluster-vpc-subnets-private" {
    vpc_id            = "${aws_vpc.cluster-vpc.id}"
    count             = "${length(var.aws_avail_zones)}"
    availability_zone = "${element(var.aws_avail_zones, count.index)}"
    cidr_block        = "${element(var.aws_cidr_subnets_private, count.index)}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-${element(var.aws_avail_zones, count.index)}-private",
    ))}"
}

resource "aws_db_subnet_group" "cluster-vpc-db-subnets-private" {
  name       = "db-private"
  subnet_ids = ["${aws_subnet.cluster-vpc-subnets-private.*.id}"]

  tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-db-private",
  ))}"
}

# Routing in VPC
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.cluster-vpc.id}"

    route {
        cidr_block = "${var.aws_anywhere_ip}"
        gateway_id = "${aws_internet_gateway.cluster-vpc-internetgw.id}"
    }

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-routetable-public",
    ))}"
}

resource "aws_route_table" "semi-private" {
    count  = "${length(var.aws_cidr_subnets_private)}"
    vpc_id = "${aws_vpc.cluster-vpc.id}"

    route {
        cidr_block     = "${var.aws_anywhere_ip}"
        nat_gateway_id = "${element(aws_nat_gateway.cluster-nat-gateway.*.id, count.index)}"
    }

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-routetable-semi-private-${count.index}",
    ))}"
}

resource "aws_route_table" "private" {
    count  = "${length(var.aws_cidr_subnets_private)}"
    vpc_id = "${aws_vpc.cluster-vpc.id}"

    tags = "${merge(var.default_tags, map(
        "Name", "${var.aws_cluster_name}-routetable-private-${count.index}",
    ))}"
}

resource "aws_route_table_association" "public" {
    count          = "${length(var.aws_cidr_subnets_public)}"
    subnet_id      = "${element(aws_subnet.cluster-vpc-subnets-public.*.id,count.index)}"
    route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "semi-private" {
    count          = "${length(var.aws_cidr_subnets_semi_private)}"
    subnet_id      = "${element(aws_subnet.cluster-vpc-subnets-semi-private.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.semi-private.*.id,count.index)}"
}

resource "aws_route_table_association" "private" {
    count          = "${length(var.aws_cidr_subnets_private)}"
    subnet_id      = "${element(aws_subnet.cluster-vpc-subnets-private.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.private.*.id,count.index)}"
}

# Security Groups Instance
resource "aws_security_group" "base" {
    name   = "base-securitygroup"
    vpc_id = "${aws_vpc.cluster-vpc.id}"

    tags = "${merge(var.default_tags, map(
        "Name", "base-securitygroup"
    ))}"
}

resource "aws_security_group_rule" "allow-all-egress" {
    type              = "egress"
    from_port         = 0
    to_port           = 65535
    protocol          = "-1"
    cidr_blocks       = ["${var.aws_anywhere_ip}"]
    security_group_id = "${aws_security_group.base.id}"
}

resource "aws_security_group_rule" "allow-ssh-connections" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "TCP"
    cidr_blocks       = ["${var.aws_vpc_cidr_block}","${var.aws_vpn_ip}"]
    security_group_id = "${aws_security_group.base.id}"
}
