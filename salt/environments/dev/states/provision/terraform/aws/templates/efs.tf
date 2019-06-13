resource "aws_efs_file_system" "{{ configs.efs.name }}" {
  creation_token = "{{ configs.efs.name }}"

  {% if configs.efs.tags is defined -%}
  tags = {
  {%- for key, value in configs.efs.tags.items() %}
    "{{key}}" = "{{value}}"
  {%- endfor %}
  }
  {%- endif %}
}


{% for subnet in configs.efs.subnets %}
resource "aws_efs_mount_target" "subnet{{loop.index - 1}}" {
  file_system_id = "${aws_efs_file_system.{{ configs.efs.name }}.id}"
  subnet_id      = "${module.{{ configs.efs.vpc }}.private_subnets[{{loop.index - 1}}]}"
  security_groups = ["${module.{{[configs.efs.cluster_name, 'workers', 'sg'] | join('-')}}.this_security_group_id}"]
}
{% endfor %}
