applied_blockchain:
    provision:
        k8s:
            provider: aws
            cluster_name: ab-test
            bastion_size: "t2.small"
            workers:
                size: "t2.small"
                count: 2
            network:
                cidr: 10.0.0.0/16
                subnets:
                    public: ["10.0.20.0/24", "10.0.21.0/24"]
                    private: ["10.0.10.0/24", "10.0.11.0/24"]
            security:
                ssh_keys: ["tiagoacf"]
