# K8S Deployment State

This state provides an easy, single command, way to deploy a client app into its k8s cluster.

# Executing
Executing the state generates corresponding `.yaml` kubernetes files and applies them. The work folder, and location where these files are created is at `/tmp/deployment/<client_id>`

To execute the state simply run

```
$ salt-call state.apply deployment.k8s.latest pillar='{"client_id":"applied_blockchain"}'
```

**Note:** Replace `client_id` with the appropriate value.

Don't forget to clean up the output folder after you're done. By default it sits at `/tmp/deployment/<client_id>`
