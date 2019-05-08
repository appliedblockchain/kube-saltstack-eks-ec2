resource "aws_key_pair" "{{configs.key_pair.name}}" {
  key_name = "{{configs.key_pair.name}}"
  public_key = "{{configs.key_pair.public_key}}"
}
