{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - provision.tools.make_env

kubectl:
  file.managed:
    - name: {{ _configs.work_dir }}/bin/kubectl
    - mode: 755
    - source: https://storage.googleapis.com/kubernetes-release/release/v{{_configs.kubectl_version}}/bin/linux/amd64/kubectl
    - skip_verify: true
    - failhard: true
