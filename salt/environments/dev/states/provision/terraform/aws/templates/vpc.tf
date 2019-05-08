module "{{ configs.vpc.name }}" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "1.60.0"
  name               = "{{ configs.vpc.name }}"
  cidr               = "10.0.0.0/16"
  azs                = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  private_subnets    = ["{{ configs.vpc.subnets.private | map('quote') | join('\", \"')}}"]
  public_subnets     = ["{{ configs.vpc.subnets.public | map('quote') | join('\", \"') }}"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
