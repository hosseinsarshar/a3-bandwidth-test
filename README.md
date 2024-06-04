# All reduce network bandwidth test on A3 GKE Cluster

This project helps to run All Reduce network benchmark on A3 GKE clusters with 800 Gbps bandwidth. The [a3-cluster.sh](a3-cluster.sh) provide the steps needed to create and configure the GKE cluster in addition to 

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
kubectl logs --follow nccl-benchmarks-hosseins-nccl-bm-2024-05-14-121339-pod0 -c all-reduce-test
```

Login to a pod
```bash
kubectl exec -it  nccl-benchmarks-hosseins-nccl-bm-2024-05-14-121339-pod0 -c all-reduce-test
```

kubectl describe pod nccl-benchmarks-hosseins-nccl-bm-2024-05-14-121339-pod0

You should get the following log:

```bash
******* All Reduce Network Benchmark Starts *******
Number of nodes participating: 2
Cloning into 'ml-engineering'...
master_addr is only used for static rdzv_backend and when rdzv_endpoint is not specified.
WARNING:__main__:
*****************************************
Setting OMP_NUM_THREADS environment variable for each process to be 1 in default, to avoid your system being overloaded, please further tune the variable for optimal performance in your application as needed. 
*****************************************
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:1
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:2
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:3
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:4
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:5
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:The average bandwidth of all_reduce with a 4.0GB payload (5 trials, 16 ranks):
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]: algbw: 44.947 GBps (359.6 Gbps)
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]: busbw: 84.275 GBps (674.2 Gbps)
[gke-a3-cluster-a3-cluster-node-pool-2dccbe7f-j25n:0]:
******* All Reduce Network Benchmark Completes *******
```
 