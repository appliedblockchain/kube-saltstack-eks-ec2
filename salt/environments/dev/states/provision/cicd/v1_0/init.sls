{% import_yaml tpldir + "/defaults.yaml" as _configs %}
client_id_pillar:
  test.check_pillar:
    - present:
      - client_id
    - failhard: true
{%- set client_id = pillar.get("client_id") %}
{% import_yaml ("provision/tools/"+_configs.tools_version+"/defaults.yaml") as _tools_configs %}
{% do _configs.update(_tools_configs) %}

{{ _configs.work_dir }}/{{ client_id }}:
  file.directory:
    - makedirs: True


k8s_provision_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:provision:cicd
    - failhard: true
{%- set _pillar = salt.pillar.get(client_id + ":provision:cicd") %}

k8s_authentication_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:authentication:{{ _pillar.provider }}:saltstack:aws_access_key_id
      - {{ client_id }}:authentication:{{ _pillar.provider }}:saltstack:aws_secret_access_key
    - failhard: true
{%- set _auth = salt.pillar.get([client_id, 'authentication',_pillar.provider]|join(':')) -%}


{%- set configs_dir = tpldir + '/templates/configs/'-%}
{%- set common_configs_dir = 'provision/terraform/'+_pillar.provider+'/configs/'-%}

# Setup Tools

include:
  - provision.tools.install_terraform
  - provision.tools.install_aws_iam_authenticator

# Make sure plan file exists in FS so you can simply append to it
{{ [_configs.work_dir, client_id, _configs.tf_plan_file] | join("/") }}:
    file.managed:
        - require:
            - tools_dir
            

{% from "provision/terraform/common/functions.j2" import load_terraform_template with context %}



{% from common_configs_dir + 'provider_configs.j2' import provider_configs with context%}
{% from common_configs_dir + 'terraform_backend_configs.j2' import terraform_backend_configs with context %}
{% from configs_dir + 'vpc_configs.j2' import vpc_configs with context %}
{% set security_groups = [] %}
{% for sg in ['cicd','bastion'] %}
    {% do security_groups.append({'security_group': {
        'name': ['cicd-ab', sg, 'sg'] | join('-'),
        'vpc': vpc_configs.vpc.name,
        'rules': tpldir + '/templates/sg_rules/' + sg + '.tf'
    }}) %}
{% endfor %}
{% from configs_dir + 'ami_configs.j2' import ami_configs with context %}
{% from configs_dir + 'bastion_configs.j2' import bastion_configs with context %}
{% from configs_dir + 'eip_configs.j2' import eip_configs with context %}

# Setup Provider 
{{ load_terraform_template("provider", provider_configs) }}

# Terraform Backend
{{ load_terraform_template("terraform_backend", terraform_backend_configs) }}

# Setup AZ and VPC
{{ load_terraform_template("availability_zones") }}
{{ load_terraform_template("vpc", vpc_configs) }}

# Setup Security Groups
{% for sg_config in security_groups %}
{{ load_terraform_template("security_group", sg_config, index=loop.index) }}
{% endfor %}

# Setup SSH Keys
{%- set keys = [_pillar.bastion_default_ssh_key]-%}
{%- for vm in _pillar.virtual_machines -%}
  {%- for key in vm.security.ssh_keys -%}
    {%- do keys.append(key) -%}
  {%- endfor -%}
{%- endfor -%}

{%- for key_name in (keys|unique) -%}
 {%- for key in _auth.ssh_keys -%}
  {%- if key_name == key.name -%}
      {%- set key_pair_configs = { 'key_pair': {
            'name': key.name,
            'public_key': key.public_key }}%}
{{ load_terraform_template("key_pair", key_pair_configs, index=loop.index)}}
  {%- else %}
{{ key_name }}_missing_key_definition:
  test.fail_without_changes:
    - name: "Missing ssh key defininion for: {{ key_name }}. Check pillar <client_id>:authentication:<provider>:ssh_keys"
    - failhard: true
  {%- endif -%}
 {%- endfor -%}
{%- endfor -%}


# Setup EC2 Bastion
{{ load_terraform_template("ami", ami_configs)}} # AMI - Bastion Instance Image
{{ load_terraform_template("ec2", bastion_configs)}} # Bastion Intance
{{ load_terraform_template("eip", eip_configs)}} # Elastic IP (public)

# Generate Bastion Cloud-init
{{ bastion_configs.ec2.cloud_init_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/cloud_init/cloud-init-bastion.conf
    - failhard: True
    - defaults:
      instance_configs: {{ bastion_configs }}


{%- for vm in _pillar.virtual_machines -%}
  {%- set count = vm.instances if vm.instances is defined else 1 -%}  
  {%- for i in range(count)  %}
    {%- set vm_name = ['cicd-ab', vm.name, (i + 1) | string] | join('-') -%}
    {%- set cloud_init_file = [_configs.work_dir, client_id, 'cloud-init-' + vm_name] | join('/') -%}

    # Set VM Configs
    {% set vm_configs = { 'ec2': {
      'name': vm_name,
      'size': vm.size,
      'security_group': 'cicd-ab-cicd-sg',
      'subnet_id': "${element(module." + vpc_configs.vpc.name + ".private_subnets, 0)}",
      'ami': 'vm-ami',
      'cloud_init_file': cloud_init_file,
      'key': vm.security.default_ssh_key
    }}%}

    # Set Cloud-Init File (Pulls cloud-init-<VM Name> if exists, else falls back to default)
    {% if salt.file.file_exists('/srv/salt/environments/' + salt.pillar.get('env') +'/states/' + tpldir + '/templates/cloud_init/cloud-init-' + vm.name + '.conf') -%}
      {%- set cloud_init_source = 'salt://' + tpldir + '/templates/cloud_init/cloud-init-' + vm.name + '.conf' -%}
    {%- else -%}
      {%- set cloud_init_source = 'salt://' + tpldir + '/templates/cloud_init/cloud-init-vm.conf' -%}
    {%- endif %}

{{ vm_configs.ec2.cloud_init_file }}:
  file.managed:
    - template: jinja
    - source: {{ cloud_init_source }}
    - failhard: True
    - defaults:
      instance_configs: {{ vm_configs }}

{{ load_terraform_template("ec2", vm_configs, i+1)}} 
  {%- endfor -%}
{%- endfor -%}
