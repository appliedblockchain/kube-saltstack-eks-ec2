applied_blockchain:
    deployment:
        k8s:
            provider: aws
            domain:
                name: abtech.dev
                cert64: {{ salt.nacl.dec('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') }}
                cert_key64: {{ salt.nacl.dec('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')}}
            apps:
                - name: k8s-deploy-test
                  replicas: 1
                  port: 8000
                  image: crccheck/hello-world
                  tag: latest # The use of latest is really bad. This field has to go.
                  public_access: true
                  storage:
                    size: 1Gi
                    mount_path: /datadrive/clusterstorage
                - name: api
                  replicas: 2
                  port: 8080
                  image: appliedblockchain/emsurge-api-dev
                  tag: latest # The use of latest is really bad. This field has to go.
                  public_access: true
                  static_env_vars:
                    - name: NODE_ENV
                      value: development
                    - name: JWT_SECRET
                      value: emsurgeJwtSecret
                    - name: APP_URL
                      value: https://app.abtech.dev/
                  requires_database: true
                  registry:
                    server: https://index.docker.io/v1/
                    username: abturing
                    password: {{ salt.nacl.dec('kvBab0RRK9yLaUgFwMVaACnXMhKoO7zHYtBCp1gAXRixWUjd5ZTSKPI6BXGbe7vhCxBEKdxii2ChaK0efemY7ga1lmANCVEo') }}
                - name: app
                  replicas: 2
                  port: 80
                  image: appliedblockchain/emsurge-app-dev
                  tag: latest # The use of latest is really bad. This field has to go.
                  static_env_vars:
                    - name: NODE_ENV
                      value: development
                    - name: API_BASE_URL
                      value: https://api.abtech.dev/api
                  public_access: true
                  registry:
                    server: https://index.docker.io/v1/
                    username: abturing
                    password: {{ salt.nacl.dec('kvBab0RRK9yLaUgFwMVaACnXMhKoO7zHYtBCp1gAXRixWUjd5ZTSKPI6BXGbe7vhCxBEKdxii2ChaK0efemY7ga1lmANCVEo') }}
                - name: worker
                  image: appliedblockchain/emsurge-worker-dev
                  tag: latest # The use of latest is really bad. This field has to go.
                  requires_database: true
                  static_env_vars:
                    - name: NODE_ENV
                      value: development
                  registry:
                    server: https://index.docker.io/v1/
                    username: abturing
                    password: {{ salt.nacl.dec('kvBab0RRK9yLaUgFwMVaACnXMhKoO7zHYtBCp1gAXRixWUjd5ZTSKPI6BXGbe7vhCxBEKdxii2ChaK0efemY7ga1lmANCVEo') }}
            job:
                - name: database-migrations
                  image: appliedblockchain/emsurge-db-migrate
                  command: "npm run migrate"
                  tag: latest
                  requires_database: true
                  registry:
                    server: https://index.docker.io/v1/
                    username: abturing
                    password: {{ salt.nacl.dec('kvBab0RRK9yLaUgFwMVaACnXMhKoO7zHYtBCp1gAXRixWUjd5ZTSKPI6BXGbe7vhCxBEKdxii2ChaK0efemY7ga1lmANCVEo') }}
