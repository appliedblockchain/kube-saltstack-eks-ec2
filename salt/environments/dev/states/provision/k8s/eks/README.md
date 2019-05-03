# EKS Provision State

# Executing
Executing `EKS` state generates the corresponding *HCL* code and runs `terraform plan` into an `.tfstate`file in order to then manually execute `terraform apply`. Since this is a sensitivy operation we should always intervene when changing infrastructure with code.

To execute the state simply run

```
$ salt-call state.apply provision.k8s.eks.latest pillar='{"client_id":"applied_blockchain"}'
```

**Note:** Replace `client_id` with the appropriate value.

# Outputs
When running the state the **output** from the `terraform` both `init` and `plan` are stored in files and the changes expected to be done are printed to stdout inside the state execution output. The output details the files locations.

# Clean Up

Don't forget to clean up the output folder after you're done. By default it sits at `/tmp/k8s`
