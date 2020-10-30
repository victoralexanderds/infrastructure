Tech Stack

Provisioning
- Infrastructure : terraform
- k8s cluster: kops

Application
- Base: dockerize
- Hub: AWS ECR

Managed Service:
- Casandra: AWS Keyspace
- PostgreSQL: RDS PostgreSQL


Step:
1. Infrastructure Provisioning
    1 . Terraform, will create infrastructure:
    - VPC     : with CIDR 10.0.0.0/16 for staging
    - Subnet  : 3 subnet (public, private and private with nat) / zone
    - Route   : Internal, Public and with NAT
    - Security Group  : Base sec-group ssh and web http(s)
    
    2 . k8s cluster with kops:
    -  kops will create k8s cluster on top of VM
    -  Master : 1 per zone
    -  Worker : start with 1 per zone with as enabled
2. CI/CD Provisiong
3. Application Deployment
4. 