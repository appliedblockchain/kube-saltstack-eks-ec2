dev:
  '*':
    - env
  '*saltmaster*':
    - provision/cicd/applied_blockchain
    - provision/k8s/applied_blockchain
    - deployment/k8s/applied_blockchain
    - authentication/aws/applied_blockchain
    - authentication/dns/applied_blockchain
  '*.dev.*':
    - example
