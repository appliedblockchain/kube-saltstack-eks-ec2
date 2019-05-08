dev:
  '*saltmaster*':
    - provision/cicd/applied_blockchain
    - provision/k8s/applied_blockchain
    - authentication/aws/applied_blockchain
  '*.dev.*':
    - example
