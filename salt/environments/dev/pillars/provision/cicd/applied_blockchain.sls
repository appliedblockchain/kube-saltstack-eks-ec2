applied_blockchain:
    provision:
        cicd:
          provider: aws
          network:
            cidr: 10.0.0.0/16
            subnets:
                public: ["10.0.10.0/24", "10.0.11.0/24"]
                private: ["10.0.20.0/24", "10.0.21.0/24"]
          bastion_default_ssh_key: tiagoacf
          virtual_machines:
            - name: saltmaster
              size: "t2.small"
              instances: 1
              subnet:
              security:
                ssh_keys: ["tiagoacf"]
