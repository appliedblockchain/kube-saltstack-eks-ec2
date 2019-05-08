{% import_yaml tpldir + "/defaults.yaml" as _configs %}

tools_dir:
    file.directory:
        - name: {{ _configs.work_dir }}/bin
        - makedirs: True

unzip:
    pkg.installed
