{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env
  
python3:
  pkg.installed:
    - pkgs:
      - python3
      - python3-pip
    - failhard: true
