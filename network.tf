module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"
  name    = "tf-flask-app"
  cidr    = "10.5.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.5.1.0/24", "10.5.2.0/24"]
  public_subnets  = ["10.5.10.0/24", "10.5.20.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_dhcp_options    = true

  tags = {
    Terraform = "true"
  }
}