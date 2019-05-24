{% import_yaml tpldir + "/defaults.yaml" as _configs %}
include:
  - tools.make_env
  
aws-iam-authenticator:
  file.managed:
    - name: {{ _configs.tools_work_dir }}/aws-iam-authenticator
    - source: https://amazon-eks.s3-us-west-2.amazonaws.com/{{_configs.aws_iam_auth_version}}/bin/linux/amd64/aws-iam-authenticator
    - source_hash: https://amazon-eks.s3-us-west-2.amazonaws.com/{{_configs.aws_iam_auth_version}}/bin/linux/amd64/aws-iam-authenticator.sha256
    - mode: 755
    - failhard: true
