  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      description              = "Allow access to workers from control plane"
      source_security_group_id = module.{{[_pillar.cluster_name, 'control-plane', 'sg'] | join('-')}}.this_security_group_id
    },
    {
      rule                     = "all-all"
      description              = "Inter worker access"
      source_security_group_id = module.{{[_pillar.cluster_name, 'workers', 'sg'] | join('-')}}.this_security_group_id
    },
    {
      rule                     = "ssh-tcp"
      description              = "Allow access to workers from bastion"
      source_security_group_id = module.{{[_pillar.cluster_name, 'bastion', 'sg'] | join('-')}}.this_security_group_id
    },
    {
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Allow access to workers from control plane"
      source_security_group_id = module.{{[_pillar.cluster_name, 'control-plane', 'sg'] | join('-')}}.this_security_group_id
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 4
  egress_rules        = ["all-all"]
