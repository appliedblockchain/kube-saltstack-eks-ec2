  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      description              = "Allow access to cicd vm from bastion"
      source_security_group_id = "${module.cicd-ab-bastion-sg.this_security_group_id}"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  egress_rules        = ["all-all"]
