## All reduce network bandwidth test

Deploy the helm package
```bash
helm install "${USER}-nccl-bm" .
```

Find your `master pod`
```bash
kubectl get pods | grep "${USER}-nccl-bm.*pod0"
```

Get the logs
```bash
kubectl logs --follow <master-pod-name> -c all-reduce-test
```

 