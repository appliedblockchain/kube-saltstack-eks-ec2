{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env
  
awscli:
  pip.installed:
    - name: awscli
    - bin_env: '/usr/bin/pip3'
    - require:
      - pkg: python3
    - failhard: true
