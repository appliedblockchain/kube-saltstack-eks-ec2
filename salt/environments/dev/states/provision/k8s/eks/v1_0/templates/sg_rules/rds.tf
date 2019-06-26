computed_ingress_with_source_security_group_id = [
  {
    rule                     = "all-all"
    description              = "Worker  access"
    source_security_group_id = "${module.{{[_pillar.cluster_name, 'workers', 'sg'] | join('-')}}.this_security_group_id}"
  },
  {
    rule                     = "all-all"
    description              = "Allow access to rds from bastion"
    source_security_group_id = "${module.{{[_pillar.cluster_name, 'bastion', 'sg'] | join('-')}}.this_security_group_id}"
  },
]
number_of_computed_ingress_with_source_security_group_id = 2
egress_rules        = ["all-all"]
