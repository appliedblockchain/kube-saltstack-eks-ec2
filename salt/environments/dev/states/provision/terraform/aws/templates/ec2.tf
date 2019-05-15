module "{{ configs.ec2.name }}" {
  source = "terraform-aws-modules/ec2-instance/aws"

  instance_count = 1

  name                        = "{{ configs.ec2.name }}"
  key_name                    = "{{ configs.ec2.key }}"
  ami                         = "${data.aws_ami.{{ configs.ec2.ami }}.id}"
  instance_type               = "{{ configs.ec2.size }}"
  subnet_id                   = "{{ configs.ec2.subnet_id }}"
  vpc_security_group_ids      = ["${module.{{ configs.ec2.security_group }}.this_security_group_id}"]
  associate_public_ip_address = {{ configs.ec2.public_ip_address if configs.ec2.public_ip_address is defined else 'false'}}
  user_data                   = "${file("{{ configs.ec2.cloud_init_file }}")}"

  root_block_device = [{
    volume_type = "gp2"
    volume_size = 10
  }]
}
