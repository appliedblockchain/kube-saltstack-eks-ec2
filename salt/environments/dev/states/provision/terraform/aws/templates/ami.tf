data "aws_ami" "{{configs.ami.name}}" {
    most_recent = true

    filter {
        name   = "name"
        values = ["{{configs.ami.ami_name}}"]
    }

    filter {
        name   = "virtualization-type"
        values = ["{{configs.ami.virtualization_type}}"]
    }

    owners = ["{{configs.ami.ami_owner}}"]
}
