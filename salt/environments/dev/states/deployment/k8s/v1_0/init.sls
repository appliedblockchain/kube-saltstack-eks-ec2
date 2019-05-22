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

deployment_test_pillar:
  test.check_pillar:
    - present:
      - {{ client_id }}:deployment:k8s
      - {{ client_id }}:provision:k8s:cluster_name
    - failhard: true
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

{%- set _auth = salt.pillar.get([client_id, 'authentication', _cluster.provider]|join(':')) %}

include:
    - tools.install_python3
    - tools.install_awscli
    - tools.install_kubectl

{%- set base_app_dir = [_configs.work_dir, client_id] | join("/") -%}
{%- set kubeconfig = [base_app_dir, "kubeconfig"] | join("/") %}

{{kubeconfig}}:
    cmd.run:
        - name: |
            aws eks --region {{ _configs.region}} update-kubeconfig --name {{ _cluster.cluster_name }} --kubeconfig {{ kubeconfig }}
        - env:
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require: 
            - awscli

{%- for app in _deploy.apps %}
{%- set deployment_yaml = [base_app_dir, app.name + "_deployment.yaml"] | join("/") %}
{%- set service_yaml = [base_app_dir, app.name + "_service.yaml"] | join("/") %}

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

{{ service_yaml }}:
  file.managed:
    - template: jinja
    - source: salt://{{tpldir}}/templates/service.yaml.j2
    - failhard: True
    - defaults:
        provider: {{ _cluster.provider}}
        name: {{ app.name }}
        port: {{ app.port }}
        {% if app.public_access %}public_access: {{ app.public_access }}{% endif %}


{{ app.name }}_deploy:
    cmd.run:
        - name: |
            {{ _configs.tools_work_dir }}/kubectl apply -f {{ deployment_yaml }} --kubeconfig {{ kubeconfig }}
            {{ _configs.tools_work_dir }}/kubectl apply -f {{ service_yaml }} --kubeconfig {{ kubeconfig }}
        - env:
            - AWS_ACCESS_KEY_ID: {{ _auth.saltstack.aws_access_key_id}}
            - AWS_SECRET_ACCESS_KEY: {{ _auth.saltstack.aws_secret_access_key}}
        - require:
          - {{kubeconfig}}

{%- endfor %}
