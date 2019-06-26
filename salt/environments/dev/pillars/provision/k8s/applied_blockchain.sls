applied_blockchain:
    provision:
        k8s:
            provider: aws
            cluster_name: ab-test
            bastion_size: "t2.small"
            bastion_default_ssh_key: turing
            cluster_storage: true
            database:
                instance_size: "db.t2.large"
                storage_size: 5 # GB
                username: abuser # since this cluster if for process testing purposes the credentials will be in plain text
                password: abpass1234
            workers:
                size: "c5.large"
                count: 2
            network:
                cidr: 10.0.0.0/16
                subnets:
                    public: ["10.0.20.0/24", "10.0.21.0/24"]
                    private: ["10.0.10.0/24", "10.0.11.0/24"]
            security:
                ssh_keys: ["tiagoacf", "turing"]
