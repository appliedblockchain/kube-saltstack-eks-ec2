module "{{ configs.security_group.name }}" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.7.0"

  name        = "{{ configs.security_group.name }}"
  vpc_id      = "${module.{{ configs.security_group.vpc }}.vpc_id}"

  {% include configs.security_group.rules with context %}
}
