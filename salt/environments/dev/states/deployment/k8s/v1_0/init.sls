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

# Deploy Apps
{%- for app in _deploy.apps %}
{%- set deployment_yaml = [base_app_dir, app.name + "_deployment.yaml"] | join("/") %}
{%- set service_yaml = [base_app_dir, app.name + "_service.yaml"] | join("/") %}
{%- if app.registry is defined -%}
{%- set regcred_name = app.name + "-regcred" -%}
{%- endif %}

{{ deployment_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/deployment.yaml.j2
    - failhard: True
    - defaults:
        provider: {{ _cluster.provider}}
        name: {{ app.name }}
        replicas: {{ app.replicas }}
        image: {{ app.image }}
        tag: {{ app.tag }}
        port: {{ app.port }}
        {% if app.registry is defined -%}
        regsecret: {{ regcred_name }}
        {%- endif %}

{{ service_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/service.yaml.j2
    - failhard: True
    - defaults:
        name: {{ app.name }}
        port: {{ app.port }}

{{ app.name }}_deploy:
    cmd.run:
        - name: |
            kubectl create namespace {{ apps_namespace }}
            {% if app.registry is defined -%}
            kubectl create secret docker-registry {{ regcred_name }} --docker-server={{app.registry.server}} --docker-username={{app.registry.username}} --docker-password={{app.registry.password}} -n {{ apps_namespace }}
            {%- endif %}
            kubectl apply -f {{ deployment_yaml }} -n {{ apps_namespace }}
            kubectl apply -f {{ service_yaml }} -n {{ apps_namespace }}
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{kubeconfig}}

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
            kubectl get ing {{ ingress_name }} -n {{ apps_namespace }} -o yaml | grep "hostname:" | tail -1 | cut -c 17- > {{ _configs.work_dir }}/{{ client_id }}_external_ip
            [ `cat {{ _configs.work_dir }}/{{ client_id }}_external_ip | wc -c` -gt 1 ]
        - env:
            - PATH: {{ path_var }}
            - KUBECONFIG: {{ kubeconfig }}
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{ kubeconfig }}
          - {{ ingress_service }}
        - retry: # On full stack deploy, ELB may take a while to create
            attempts: 7
            interval: 60
            splay: 30

{% for app in _deploy.apps %}
{{ app.name}}_{{ client_id }}_dns:
  dnsimple.cname_present:
    - client_id: {{ client_id }}
    - domain: {{ _deploy.domain.name }}
    - name: {{ app.name }}
    - content_file: {{ _configs.work_dir+"/"+ client_id + "_external_ip" }}
    - require:
      - {{ client_id }}_get_external_ip
      - domain_test_pillar
{% endfor %}
