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

{%- set _cluster = salt.pillar.get([client_id, "provision", "k8s"] | join(":")) %}
{%- set _deploy = salt.pillar.get([client_id, "deployment", "k8s"] | join(":")) %}

{%- if _cluster.provider == 'aws' %}
authentication_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:authentication:{{ _cluster.provider }}:saltstack:aws_access_key_id
      - {{ client_id }}:authentication:{{ _cluster.provider }}:saltstack:aws_secret_access_key
    - failhard: true
{%- endif %}

domain_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:deployment:k8s:domain:name
      - {{ client_id }}:deployment:k8s:domain:cert64
      - {{ client_id }}:deployment:k8s:domain:cert_key64
    - failhard: true

{%- set _auth = salt.pillar.get([client_id, 'authentication', _cluster.provider]|join(':')) %}

include:
    - tools.install_python3
    - tools.install_awscli
    - tools.install_kubectl
    - tools.install_git

{% set current_path = salt['environ.get']('PATH') %}
{% set path_var = current_path + ':' + _configs.tools_work_dir %}

{%- set base_app_dir = [_configs.work_dir, client_id] | join("/") -%}
{%- set kubeconfig = [base_app_dir, "kubeconfig"] | join("/") %}

{{kubeconfig}}:
    cmd.run:
        - name: |
            aws eks --region {{ _configs.region}} update-kubeconfig --name {{ _cluster.cluster_name }} --kubeconfig {{ kubeconfig }}
        - env:
            - PATH: {{ path_var }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - failhard: true
        - require:
            - awscli

# Deploy Nginx Ingress
{% set nginx_service = base_app_dir + "/nginx_service.yaml" %}
{{ base_app_dir }}/kustomization.yaml:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/nginx_kustomization.yaml
    - failhard: True

{{ nginx_service }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/nginx_service.yaml
    - failhard: True

nginx_ingress_deploy:
    cmd.run:
        - name: |
            kubectl create namespace ingress-nginx
            kubectl apply --kustomize {{ base_app_dir }}/
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - failhard: true
        - require:
          - {{kubeconfig}}
          - git

{%- set apps_namespace = client_id|replace('_','-') %}

# Setup Certificates
{%- set cert_file = [base_app_dir, client_id + "_cert.pem"] | join("/") %}
{%- set cert_key = [base_app_dir, client_id + "_cert.key"] | join("/") %}
{{ cert_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/base64_decode.j2
    - failhard: true
    - defaults:
        content: {{ _deploy.domain.cert64 }}

{{ cert_key }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/base64_decode.j2
    - failhard: true
    - defaults:
        content: {{ _deploy.domain.cert_key64 }}

# Setup EFS Provisioner
# https://github.com/kubernetes-incubator/external-storage/tree/master/aws/efs
{%- set efs_yaml = [base_app_dir, client_id + "_efs.yaml"] | join("/") %}
{{ efs_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/efs.yaml.j2
    - failhard: true
    - defaults:
        system_id: {{ salt.aws_utils.get_efs_system_id(creation_token=_cluster.cluster_name+'-shared-storage',client_id=client_id,region=_configs.region) }}
        region: {{ _configs.region }}
        namespace: {{ apps_namespace }}

{{ efs_yaml }}_deploy:
    cmd.run:
        - name: |
            kubectl create namespace {{ apps_namespace }}
            kubectl apply -f {{ efs_yaml }} -n {{ apps_namespace }}
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}

# Deploy Apps
{%- for app in _deploy.apps %}
{%- if app.storage is defined %}
  {%- set deploy_yaml = [base_app_dir, app.name + "_statefulset.yaml"] | join("/") %}
{%- else %}
  {%- set deploy_yaml = [base_app_dir, app.name + "_deployment.yaml"] | join("/") %}
{%- endif %}
{%- set service_yaml = [base_app_dir, app.name + "_service.yaml"] | join("/") %}
{%- if app.registry is defined -%}
{%- set regcred_name = app.name + "-regcred" -%}
{%- endif %}

# Set container env_vars
{%- set env_vars = {} -%}
{%- if app.requires_database is defined and app.requires_database -%}
  {%- set rds_name = _cluster.cluster_name|replace('-','') -%} # As defined in rds_configs.j2
  {%- set rds_identifier = _cluster.cluster_name|replace('-','') + '-postgres' -%} # As defined in rds.tf
  {% do env_vars.update({'DB_CONNECTION': 'postgresql://'+ _cluster.database.username +':'+ _cluster.database.password +'@'+ salt.aws_utils.get_rds_endpoint(db_identifier=rds_identifier, client_id=client_id, region=_configs.region) +':5432/'+ rds_name}) %}
{%- endif -%}

{%- if app.static_env_vars is defined %}
{%- for var in app.static_env_vars %}
{% do env_vars.update({var.name: var.value}) %}
{%- endfor %}
{%- endif %}


{{ deploy_yaml }}:
  file.managed:
    - template: jinja
    {% if app.storage is defined -%}
    - source: salt://{{tpldir}}/templates/statefulset.yaml.j2
    {%- else %}
    - source: salt://{{tpldir}}/templates/deployment.yaml.j2
    {%- endif %}
    - failhard: True
    - defaults:
        provider: {{ _cluster.provider}}
        name: {{ app.name }}
        {% if app.replicas is defined -%}
        replicas: {{ app.replicas }}
        {%- else %}
        replicas: 1
        {%- endif %}
        image: {{ app.image }}
        tag: {{ app.tag }}
        {% if app.port is defined -%}
        port: {{ app.port }}
        {%- endif %}
        env_vars: {{ env_vars }}
        {% if app.registry is defined -%}
        regsecret: {{ regcred_name }}
        {%- endif %}
        {% if app.storage is defined -%}
        storage: {{ app.storage }}
        {%- endif %}

{%- if app.public_access is defined and app.public_access %}
{{ service_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/service.yaml.j2
    - failhard: True
    - defaults:
        name: {{ app.name }}
        port: {{ app.port }}
{%- endif %}

{{ app.name }}_deploy:
    cmd.run:
        - name: |
            {% if app.registry is defined -%}
            kubectl create secret docker-registry {{ regcred_name }} --docker-server={{app.registry.server}} --docker-username={{app.registry.username}} --docker-password={{app.registry.password}} -n {{ apps_namespace }}
            {%- endif %}
            kubectl apply -f {{ deploy_yaml }} -n {{ apps_namespace }}
            {%- if app.public_access is defined and app.public_access %}
            kubectl apply -f {{ service_yaml }} -n {{ apps_namespace }}
            {%- endif %}
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}
        {%- if app.storage is defined %}
          - {{ efs_yaml }}_deploy
        {%- endif %}

{%- endfor %}

{%- set ingress_service = [base_app_dir, client_id + "_ingress_service.yaml"] | join("/") %}
{%- set ingress_name = "ingress-" + (client_id|replace('_','-')) %}
{{ ingress_service }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/ingress_service.yaml.j2
    - failhard: True
    - defaults:
        apps: {{ _deploy.apps }}
        ingress: {{ ingress_name }}
        domain: {{ _deploy.domain.name }}
    - require:
      - domain_test_pillar

{{ ingress_service }}_deploy:
    cmd.run:
        - name: |
            kubectl create secret tls {{ _deploy.domain.name }} --key {{ cert_key }} --cert {{ cert_file }} -n {{ apps_namespace }}
            kubectl apply -f {{ ingress_service }} -n {{ apps_namespace }}
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}
          - {{ cert_key }}
          - {{ cert_file }}
          - {{ ingress_service }}
          {%- for app in _deploy.apps %}
          - {{ app.name }}_deploy
          {%- endfor %}

{{ client_id }}_get_external_ip:
    cmd.run:
        - name: |
            kubectl get ing {{ ingress_name }} -n {{ apps_namespace }} -o yaml | grep "hostname:" | tail -1 | cut -c 17- > {{ _configs.work_dir }}/{{ client_id }}/external_ip
            [ `cat {{ _configs.work_dir }}/{{ client_id }}/external_ip | wc -c` -gt 1 ]
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}
          - {{ ingress_service }}
        - retry: # On full stack deploy, ELB may take a while to create
            attempts: 10
            interval: 60
            splay: 30

{% for app in _deploy.apps %}
{{ app.name }}_{{ client_id }}_dns:
  dnsimple.cname_present:
    - client_id: {{ client_id }}
    - domain: {{ _deploy.domain.name }}
    - name: {{ app.name }}
    - content_file: {{ _configs.work_dir+"/"+ client_id + "/external_ip" }}
    - require:
      - {{ client_id }}_get_external_ip
      - domain_test_pillar
{% endfor %}


{% for job in _deploy.job %}

{%- set env_vars = {} -%}
{%- if job.requires_database is defined and job.requires_database -%}
  {%- set rds_name = _cluster.cluster_name|replace('-','') -%} # As defined in rds_configs.j2
  {%- set rds_identifier = _cluster.cluster_name|replace('-','') + '-postgres' -%} # As defined in rds.tf
  {% do env_vars.update({'DB_CONNECTION': 'postgresql://'+ _cluster.database.username +':'+ _cluster.database.password +'@'+ salt.aws_utils.get_rds_endpoint(db_identifier=rds_identifier, client_id=client_id, region=_configs.region) +':5432/'+ rds_name}) %}
{%- endif -%}

{%- if job.static_env_vars is defined %}
  {%- for var in job.static_env_vars %}
    {% do env_vars.update({var.name: var.value}) %}
  {%- endfor %}
{%- endif %}

{%- set job_yaml = [base_app_dir, job.name + "_job.yaml"] | join("/") %}
{%- set regcred_name = job.name + "-regcred" %}

{{ job_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/job.yaml.j2
    - failhard: True
    - defaults:
        name: {{ job.name }}
        image: {{ job.image }}
        command: {{ job.command }}
        tag: {{ job.tag }}
        env_vars: {{ env_vars }}
        {% if job.registry is defined -%}
        regsecret: {{ regcred_name }}
        {%- endif %}

{{ job.name }}_deploy:
    cmd.run:
        - name: |
            {% if job.registry is defined -%}
            kubectl create secret docker-registry {{ regcred_name }} --docker-server={{job.registry.server}} --docker-username={{job.registry.username}} --docker-password={{job.registry.password}} -n {{ apps_namespace }}
            {%- endif %}
            kubectl delete job {{ job.name }} -n {{ apps_namespace }}
            kubectl apply -f {{ job_yaml }} -n {{ apps_namespace }}
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}
{% endfor %}
