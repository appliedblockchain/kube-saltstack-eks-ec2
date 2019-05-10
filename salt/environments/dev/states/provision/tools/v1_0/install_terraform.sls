{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - provision.tools.make_env
  
terraform_{{_configs.tf_version}}_linux_amd64.zip:
  file.managed:
    - name: {{ _configs.work_dir }}/bin/terraform.zip
    - source: https://releases.hashicorp.com/terraform/{{_configs.tf_version}}/terraform_{{_configs.tf_version}}_linux_amd64.zip
    - source_hash: https://releases.hashicorp.com/terraform/{{_configs.tf_version}}/terraform_{{_configs.tf_version}}_SHA256SUMS
    - failhard: true

{{ _configs.work_dir }}/bin/:
  archive.extracted:
    - source: {{ _configs.work_dir }}/bin/terraform.zip
    - enforce_toplevel: false
    - use_cmd_unzip: true
    - failhard: true
