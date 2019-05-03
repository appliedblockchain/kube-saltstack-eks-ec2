{% import_yaml tpldir + "/defaults.yaml" as _configs %}
client_id_pillar:
  test.check_pillar:
    - present:
      - client_id
    - failhard: true
{%- set client_id = pillar.get("client_id") %}
{% do _configs.update({"work_dir": _configs.work_dir + '-' + client_id})%}

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
{%- set _auth = salt.pillar.get([client_id, 'authentication',_pillar.provider,'saltstack']|join(':')) -%}


{%- set configs_dir = tpldir + '/templates/configs/'-%}

# Setup Tools

tools_dir:
    file.directory:
        - name: {{ _configs.work_dir }}/bin
        - makedirs: True

unzip:
    pkg.installed

terraform_install:
    cmd.run:
        - name: |
            curl -s https://releases.hashicorp.com/terraform/{{_configs.tf_version}}/terraform_{{_configs.tf_version}}_linux_amd64.zip -o {{ _configs.work_dir }}/bin/terraform.zip
            unzip -o {{ _configs.work_dir }}/bin/terraform.zip -d {{ _configs.work_dir }}/bin/
        - creates: 
            - {{ _configs.work_dir }}/bin/terraform.zip
            - {{ _configs.work_dir }}/bin/terraform
        - require:
            - pkg: unzip

kubectl_install:
    cmd.run:
        - name: |
            curl -sL https://storage.googleapis.com/kubernetes-release/release/v{{_configs.kubectl_version}}/bin/linux/amd64/kubectl -o {{ _configs.work_dir }}/bin/kubectl
            chmod +x {{ _configs.work_dir }}/bin/kubectl
        - creates: {{ _configs.work_dir }}/bin/kubectl

aws_iam_authenticator_install:
    cmd.run:
        - name: |
            curl -s https://amazon-eks.s3-us-west-2.amazonaws.com/{{_configs.aws_iam_auth_version}}/bin/linux/amd64/aws-iam-authenticator -o {{ _configs.work_dir }}/bin/aws-iam-authenticator
            chmod +x {{ _configs.work_dir }}/bin/aws-iam-authenticator
        - creates: {{ _configs.work_dir }}/bin/aws-iam-authenticator


# Make sure plan file exists in FS so you can simply append to it
{{ _configs.work_dir +'/'+ _configs.tf_plan_file }}_create:
    file.managed:
        - name: {{ _configs.work_dir +'/'+ _configs.tf_plan_file }}
        - require:
            - tools_dir
            

# Load a .tf file and append it to terraform plan
{%- macro _load_template(template, configs=none, index=0) -%}
terraform_{{ _pillar.provider }}_{{ template }}_{{index}}:
  file.append:
    - name: {{ _configs.work_dir +'/'+ _configs.tf_plan_file }}
    - template: jinja
    - source: salt://provision/terraform/{{_pillar.provider}}/templates/{{template}}.tf
    - failhard: True
    {%- if configs is defined %}
    - defaults:
        configs:  {{ configs }}
        _pillar:  {{ _pillar }}
    {%- endif %}
{%- endmacro %}


{% from configs_dir + 'provider_configs.j2' import provider_configs with context%}
{% from configs_dir + 'terraform_backend_configs.j2' import terraform_backend_configs with context %}
{% from configs_dir + 'vpc_configs.j2' import vpc_configs with context %}
{% set security_groups = [] %}
{% for sg in ['control-plane','workers','bastion'] %}
    {% do security_groups.append({'security_group': {
        'name': [_pillar.cluster_name, sg, 'sg'] | join('-'),
        'vpc': vpc_configs.vpc.name,
        'rules': tpldir + '/templates/sg_rules/' + sg + '.tf'
    }}) %}
{% endfor %}
{% from configs_dir + 'bastion_ami_configs.j2' import bastion_ami_configs with context %}
{% from configs_dir + 'bastion_configs.j2' import bastion_configs with context %}
{% from configs_dir + 'eip_configs.j2' import eip_configs with context %}
{% from configs_dir + 'eks_configs.j2' import eks_configs with context %}

# Setup Provider 
{{ _load_template("provider", provider_configs) }}

# Terraform Backend
{{ _load_template("terraform_backend", terraform_backend_configs) }}

# Setup AZ and VPC
{{ _load_template("availability_zones") }}
{{ _load_template("vpc", vpc_configs) }}

# Setup Security Groups
{% for sg_config in security_groups %}
{{ _load_template("security_group", sg_config, index=loop.index) }}
{% endfor %}

# Setup SSH Keys
{%- for key in _pillar.security.ssh_keys -%}
    {%- set key_pair_configs = { 'key_pair': {
            'name': key.name,
            'public_key': key.public_key }}%}
{{ _load_template("key_pair", key_pair_configs, index=loop.index)}}
{% endfor -%}

# Setup EC2 Bastion
{{ _load_template("ami", bastion_ami_configs)}} # AMI - Bastion Instance Image
{{ _load_template("ec2", bastion_configs)}} # Bastion Intance
{{ _load_template("eip", eip_configs)}} # Elastic IP (public)

# Setup EKS Cluster
{{ _load_template("eks", eks_configs)}} # EKS Cluster

# Generate Bastion Cloud-init
{{ bastion_configs.ec2.cloud_init_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/cloud-init.conf
    - failhard: True
