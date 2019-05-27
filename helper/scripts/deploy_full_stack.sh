#!/usr/bin/env bash

CLIENT_ID="$1"
LOG_LEVEL="info"

salt-call state.apply provision.k8s.eks.latest pillar='{"client_id":"'"${CLIENT_ID}"'"}' -l $LOG_LEVEL --retcode-passthrough
cd /tmp/provision/$CLIENT_ID/ 
PATH=$PATH:/tmp/tools; terraform init; terraform apply

salt-call state.apply deployment.k8s.latest pillar='{"client_id":"'"${CLIENT_ID}"'"}' -l $LOG_LEVEL --retcode-passthrough

