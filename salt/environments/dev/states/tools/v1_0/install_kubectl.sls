{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env

kubectl:
  file.managed:
    - name: {{ _configs.tools_work_dir }}/kubectl
    - mode: 755
    - source: https://storage.googleapis.com/kubernetes-release/release/v{{_configs.kubectl_version}}/bin/linux/amd64/kubectl
    - skip_verify: true
    - failhard: true
