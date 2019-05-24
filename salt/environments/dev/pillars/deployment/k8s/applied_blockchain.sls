applied_blockchain:
    deployment:
        k8s:
            provider: aws
            apps: 
                - name: hello-world
                  replicas: 3
                  port: 8000
                  image: crccheck/hello-world
                  tag: latest # The use of latest is really bad. This field has to go.
                  public_access: true
