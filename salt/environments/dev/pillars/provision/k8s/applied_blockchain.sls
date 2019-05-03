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
                ssh_keys:
                    - name: tiagoacf
                      public_key: {{ salt.nacl.dec('+tzOHI9YCtnjiOHTVpiaATFZ9zFcZKWV67JcC/MNIF1xUtsFwYmkr4TtD+1mKWfx/UrFyGsyfOgUH3dv1XdMnWDgesW9WJV5ScZ6fB2ZWmgMByrTb4bVQZJR2iQiQ0kgg/hohIwJ1QuGX361Uax3dvSbt/abagY8TxfvC96N6qeomqUxuZtfRz4YH35S1HOZ7idF8ckzv/hcVv/tQBezRiDp08cPZZqJouWJLUUVbrTlOmHNQwbHirZ/28UVHVNtQzn81EiWdqL+ee0Cve99OdHievcTg8OjM8wqitw/oWDRt++BUd9yI4vhG/9dQ2RAfrBCiuvwe+016imifiwqwA/nCxzGZReVen0CzUmMDSm1GsTrsTUa02ktygADdu3GCR1qboKFehajRMspcKjipAuXhMQf6C0OH3EKD/ON1W/vFiL3jYNe01jIsesZC+5szuPXiBwlg6HIb2VrqyDc9kqbxFBH5PZUPDVuaS+15QSgDqbZyrr2zdUsTZ1HYkjk2hELzUcf17B0BgxplquLRrYst0WDxk4bNIxX6wR06crm+kqp8MjcMTaRTtt3A4wsyqPijtMOgZbB5oscF2My8A==')}}
