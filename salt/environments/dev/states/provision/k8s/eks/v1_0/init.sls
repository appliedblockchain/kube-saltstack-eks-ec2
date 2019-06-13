{% import_yaml tpldir + "/defaults.yaml" as _configs %}
client_id_pillar:
  test.check_pillar:
    - present:
      - client_id
    - failhard: true
{%- set client_id = pillar.get("client_id") %}
{% import_yaml ("tools/"+_configs.tools_version+"/defaults.yaml") as _tools_configs %}
{% do _configs.update(_tools_configs) %}

# Make sure client work directory exists and it's empty
{{ _configs.work_dir }}/{{ client_id }}:
  file.directory:
    - makedirs: true
    - clean: true


k8s_provision_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:provision:k8s:provider
      - {{ client_id }}:provision:k8s:cluster_name
      - {{ client_id }}:provision:k8s:bastion_size
      - {{ client_id }}:provision:k8s:workers:size
      - {{ client_id }}:provision:k8s:workers:count
      - {{ client_id }}:provision:k8s:network:cidr
      - {{ client_id }}:provision:k8s:network:subnets:public
      - {{ client_id }}:provision:k8s:network:subnets:private
      - {{ client_id }}:provision:k8s:security:ssh_keys
    - failhard: true
{%- set _pillar = salt.pillar.get(client_id + ":provision:k8s") %}

k8s_authentication_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:authentication:{{ _pillar.provider }}:saltstack:aws_access_key_id
      - {{ client_id }}:authentication:{{ _pillar.provider }}:saltstack:aws_secret_access_key
    - failhard: true
{%- set _auth = salt.pillar.get([client_id, 'authentication', _pillar.provider]|join(':')) -%}


{%- set configs_dir = tpldir + '/templates/configs/'-%}
{%- set common_configs_dir = 'provision/terraform/'+_pillar.provider+'/configs/'-%}

# Setup Tools

include:
  - tools.install_terraform
  - tools.install_aws_iam_authenticator
  - tools.install_kubectl

# Make sure plan file exists in FS so you can simply append to it
{{ [_configs.work_dir, client_id, _configs.tf_plan_file] | join("/") }}:
    file.managed:
        - require:
            - tools_dir
            

{% from "provision/terraform/common/functions.j2" import load_terraform_template with context %}


{% from common_configs_dir + 'provider_configs.j2' import provider_configs with context%}
{% from common_configs_dir + 'terraform_backend_configs.j2' import terraform_backend_configs with context %}
{% do terraform_backend_configs.terraform_backend.update({
        'key': ['terraform', salt.pillar.get('env'), client_id, 'k8s/eks', 'terraform.tfstate'] | join('/'),
}) %}
{% from configs_dir + 'vpc_configs.j2' import vpc_configs with context %}
{% set security_groups = [] %}
{% for sg in ['control-plane','workers','bastion'] %}
    {% do security_groups.append({'security_group': {
        'name': [_pillar.cluster_name, sg, 'sg'] | join('-'),
        'vpc': vpc_configs.vpc.name,
        'rules': tpldir + '/templates/sg_rules/' + sg + '.tf'
    }}) %}
{% endfor %}
{% set efs_configs = {'efs': {
    'name': _pillar.cluster_name + '-shared-storage',
    'vpc': vpc_configs.vpc.name,
    'cluster_name': _pillar.cluster_name,
    'subnets':  vpc_configs.vpc.subnets.private,
    'tags': {
        'Name': _pillar.cluster_name + + '-shared-storage',
        'provisioned_by': 'applied_blockchain',
        'provisioner': 'terraform'
    }
}} %}
{% from configs_dir + 'bastion_ami_configs.j2' import bastion_ami_configs with context %}
{% from configs_dir + 'bastion_configs.j2' import bastion_configs with context %}
{% from configs_dir + 'eip_configs.j2' import eip_configs with context %}
{% from configs_dir + 'eks_configs.j2' import eks_configs with context %}

# Workers User data file (cloud init)
{{ [_configs.work_dir, client_id, 'workers_user_data.conf' ] | join('/') }}:
  file.managed:
    - template: jinja
    - source: {{ ['salt:/', tpldir, 'templates/cloud_init/cloud-init-workers.conf'] | join('/') }}
    - failhard: True
    - defaults:
      username: {{ _pillar.bastion_default_ssh_key }}
      public_key: {{ (_auth.ssh_keys|selectattr("name", "equalto", _pillar.bastion_default_ssh_key)|map(attribute="public_key")|list)[0] }}

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

# Setup EC2 Bastion
{{ load_terraform_template("ami", bastion_ami_configs)}} # AMI - Bastion Instance Image
{{ load_terraform_template("ec2", bastion_configs)}} # Bastion Intance
{{ load_terraform_template("eip", eip_configs)}} # Elastic IP (public)

# Setup EKS Cluster
{{ load_terraform_template("eks", eks_configs)}} # EKS Cluster

# Setup EFS Storage
{{ load_terraform_template("efs", efs_configs) }}

# Generate Bastion Cloud-init
{{ bastion_configs.ec2.cloud_init_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/cloud_init/cloud-init.conf
    - failhard: True
    - defaults:
      instance_configs: {{ bastion_configs }}
