  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      description              = "Allow access to control plane from bastion"
      source_security_group_id = "${module.{{[_pillar.cluster_name, 'bastion', 'sg'] | join('-')}}.this_security_group_id}"
    },
    {
      rule                     = "https-443-tcp"
      description              = "Allow access to control plane from workers"
      source_security_group_id = "${module.{{[_pillar.cluster_name, 'workers', 'sg'] | join('-')}}.this_security_group_id}"
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 2
  computed_egress_with_source_security_group_id = [
    {
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Allow access to workers from control plane"
      source_security_group_id = "${module.{{[_pillar.cluster_name, 'workers', 'sg'] | join('-')}}.this_security_group_id}"
    },
  ]
  number_of_computed_egress_with_source_security_group_id = 1
