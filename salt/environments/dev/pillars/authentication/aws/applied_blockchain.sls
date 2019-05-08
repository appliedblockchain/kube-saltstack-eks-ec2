applied_blockchain:
    authentication:
        aws:
            saltstack:
                aws_access_key_id: {{ salt.nacl.dec('9fnRE6VRW+AKandpj9vvJygB9c95elN1NNRxjRPeiW8pJXYHp1wW2u+5Hu3ZmlTLAIsFqwMVuAj4nmZiYhDuoQFr+Zk=') }}
                aws_secret_access_key: {{ salt.nacl.dec('DnRx2XgGSoT/lBmGMlcobElTiOSNQoQt1QrjNfHGpxcupKvoltXDnO/SUCnuKdcHOpetutJDf5Cgxu8rzgPGXYZwzbWCx0c7XZ85QUyw4eSqzz8tox1bUA==') }}
            ssh_keys:
                - name: tiagoacf
                public_key: {{ salt.nacl.dec('+tzOHI9YCtnjiOHTVpiaATFZ9zFcZKWV67JcC/MNIF1xUtsFwYmkr4TtD+1mKWfx/UrFyGsyfOgUH3dv1XdMnWDgesW9WJV5ScZ6fB2ZWmgMByrTb4bVQZJR2iQiQ0kgg/hohIwJ1QuGX361Uax3dvSbt/abagY8TxfvC96N6qeomqUxuZtfRz4YH35S1HOZ7idF8ckzv/hcVv/tQBezRiDp08cPZZqJouWJLUUVbrTlOmHNQwbHirZ/28UVHVNtQzn81EiWdqL+ee0Cve99OdHievcTg8OjM8wqitw/oWDRt++BUd9yI4vhG/9dQ2RAfrBCiuvwe+016imifiwqwA/nCxzGZReVen0CzUmMDSm1GsTrsTUa02ktygADdu3GCR1qboKFehajRMspcKjipAuXhMQf6C0OH3EKD/ON1W/vFiL3jYNe01jIsesZC+5szuPXiBwlg6HIb2VrqyDc9kqbxFBH5PZUPDVuaS+15QSgDqbZyrr2zdUsTZ1HYkjk2hELzUcf17B0BgxplquLRrYst0WDxk4bNIxX6wR06crm+kqp8MjcMTaRTtt3A4wsyqPijtMOgZbB5oscF2My8A==')}}
