module "{{ configs.eks.name }}" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "{{ configs.eks.name }}"
  subnets                              = module.{{ configs.eks.vpc }}.private_subnets
  vpc_id                               = module.{{ configs.eks.vpc }}.vpc_id

  # Create Specific security group for Bastion only access to k8s Api
  cluster_create_security_group        = "false"
  cluster_security_group_id            = module.{{ configs.eks.security_group }}.this_security_group_id
  # Set EKS api endpoint access to private
  cluster_endpoint_private_access      = "true"
  cluster_endpoint_public_access       = "true"

  # Create Specific security group for workers to enable private access only for eks
  worker_groups                        = [
    {
      instance_type    = "{{ configs.eks.workers_instance_size }}"
      #subnets          = module.{{ configs.eks.vpc }}.private_subnets
      asg_desired_capacity = "{{ configs.eks.workers_instance_count }}"
      {%- if configs.eks.workers_user_data is defined %}
      additional_userdata = file("{{ configs.eks.workers_user_data }}")
      {%- endif %}
    }]
  worker_create_security_group         = "false"
  worker_security_group_id             = module.{{ configs.eks.workers_security_group }}.this_security_group_id

  # Executed by the null_resource bellow
  manage_aws_auth = false

  write_aws_auth_config = true
  write_kubeconfig = true
}


# HACKERMAN - EKS Module does not allow to override location binaries like
# kubectl, terraform, etc. As such we have to manually apply the conf file
# to allow nodes to auth in the cluster, else it will fail silently
resource "null_resource" "update_config_map_aws_auth" {
  depends_on = ["module.{{ configs.eks.name }}"]
  provisioner "local-exec" {
    working_dir = path.module
    command = "{{ configs.eks.tools_dir }}/kubectl --kubeconfig kubeconfig_{{ configs.eks.name }} apply -f config-map-aws-auth_{{ configs.eks.name }}.yaml"
    environment = {
      AWS_ACCESS_KEY_ID = "{{ configs.eks.aws_access_key_id }}"
      AWS_SECRET_ACCESS_KEY = "{{ configs.eks.aws_secret_access_key }}"
    }
  }
}
