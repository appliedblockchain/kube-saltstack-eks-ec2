  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      description              = "Allow access to workers from control plane"
      source_security_group_id = "${module.{{[_pillar.cluster_name, 'control-plane', 'sg'] | join('-')}}.this_security_group_id}"
    },
    {
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Allow access to workers from control plane"
      source_security_group_id = "${module.{{[_pillar.cluster_name, 'control-plane', 'sg'] | join('-')}}.this_security_group_id}"
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 2
  egress_rules        = ["all-all"]
