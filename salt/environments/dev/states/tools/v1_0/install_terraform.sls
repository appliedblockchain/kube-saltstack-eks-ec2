{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env
  
terraform_{{_configs.tf_version}}_linux_amd64.zip:
  file.managed:
    - name: {{ _configs.tools_work_dir }}/terraform.zip
    - source: https://releases.hashicorp.com/terraform/{{_configs.tf_version}}/terraform_{{_configs.tf_version}}_linux_amd64.zip
    - source_hash: https://releases.hashicorp.com/terraform/{{_configs.tf_version}}/terraform_{{_configs.tf_version}}_SHA256SUMS
    - failhard: true

{{ _configs.tools_work_dir }}/:
  archive.extracted:
    - source: {{ _configs.tools_work_dir }}/terraform.zip
    - enforce_toplevel: false
    - use_cmd_unzip: true
    - failhard: true
