{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env
  
git:
  pkg.installed:
    - pkgs:
      - git
    - failhard: true
