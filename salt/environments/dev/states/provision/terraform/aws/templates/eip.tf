resource "aws_eip" "{{configs.eip.name}}" {
  vpc      = true
  instance = "{{configs.eip.instance}}"
}
