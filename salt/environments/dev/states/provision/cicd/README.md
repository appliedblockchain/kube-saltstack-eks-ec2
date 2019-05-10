# CICD Provision State

# Executing
Executing `CICD` state generates *HCL* code that provisions all *cicd* related infrastructure defined in the pillar `provision > cicd > <client_id> ` Since this is a  sensitive operation we should always intervene when changing infrastructure with code.

To execute the state simply run

```
$ salt-call state.apply provision.cicd.latest pillar='{"client_id":"applied_blockchain"}'
```

**Note:** Replace `client_id` with the appropriate value.

# Outputs
All the files generated by the state, terraform plans, cloud-init, and so on are stored, by default (to change this change the `defaults.yaml` in `provision > tools` state), in `/tmp/provision/<client_id>`. Binary tools like `terraform`, `kubectl`, etc are installed at `/tmp/provision/bin`.

After executing the state you should go into the client folder `/tmp/provision/<client_id>` this folder and proceed with the *terraform workflow*

```
../bin/terraform init
../bin/terraform plan
../bin/terraform apply/destroy
```
# Clean Up

Don't forget to clean up the output folder after you're done. By default it sits at `/tmp/provision/<client_id>`