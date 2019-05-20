module "{{ configs.eks.name }}" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "{{ configs.eks.name }}"
  subnets                              = ["${module.{{ configs.eks.vpc }}.private_subnets}"]
  vpc_id                               = "${module.{{ configs.eks.vpc }}.vpc_id}"

  # Create Specific security group for Bastion only access to k8s Api
  cluster_create_security_group        = "false"
  cluster_security_group_id            = "${module.{{ configs.eks.security_group }}.this_security_group_id}"
  # Set EKS api endpoint access to private
  cluster_endpoint_private_access      = "true"
  cluster_endpoint_public_access       = "true"

  # Create Specific security group for workers to enable private access only for eks
  worker_groups                        = [
    {
      instance_type    = "{{ configs.eks.workers_instance_size }}"
      subnets          = "${join(",", module.{{ configs.eks.vpc }}.private_subnets)}"
      asg_desired_capacity = "{{ configs.eks.workers_instance_count }}"
      {%- if configs.eks.workers_user_data is defined %}
      additional_userdata = "${file("{{ configs.eks.workers_user_data }}")}"
      {%- endif %}
    }]
  worker_group_count                   = "1"
  worker_create_security_group         = "false"
  worker_security_group_id             = "${module.{{ configs.eks.workers_security_group }}.this_security_group_id}"

  write_aws_auth_config = false
  write_kubeconfig = true

  # Add binary path used in the provisioning states
  local_exec_interpreter = ["/bin/sh", "-c", "PATH=$PATH:/tmp/terraform/bin"]
}
