{% import_yaml tpldir + "/defaults.yaml" as _configs %}

tools_dir:
    file.directory:
        - name: {{ _configs.tools_work_dir }}/
        - makedirs: true
        - failhard: true

unzip:
    pkg.installed
