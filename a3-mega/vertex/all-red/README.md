# How to reproduce the distributed all-reduce test 

You can either use the built image in the `dockerhub` or build your version using the `Dockerfile` provided in this folder. The image contains the `main.sh` bash script which kicks off a `torch.distributed.run` across all the pods.

All the environment variables needed for the `TCPXO` communication is provided in the `main.sh` script.

```
git clone https://github.com/hosseinsarshar/a3-bandwidth-test.git
cd a3-bandwidth-test
```

## in GKE

Run the follwing command to create the pod

```
kubectl apply -f a3-mega/vertex/vertex-test.yaml
```

To view the logs:

```
kubectl logs --follow hosseins-nemo-0-6gqxs -c megatron
```

You should be seeting this message:

```
******* All Reduce Network Benchmark Starts *******
Number of nodes participating: 2
NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: 600000
MASTER_ADDR: nccl-host-1
fatal: destination path 'ml-engineering' already exists and is not an empty directory.
WARNING:__main__:
*****************************************
Setting OMP_NUM_THREADS environment variable for each process to be 1 in default, to avoid your system being overloaded, please further tune the variable for optimal performance in your application as needed. 
*****************************************
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:W0000 00:00:1721873127.574432 176 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:2]:W0000 00:00:1721873127.581125 180 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:1]:W0000 00:00:1721873127.574430 177 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:5]:W0000 00:00:1721873127.581401 183 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:3]:W0000 00:00:1721873127.574430 178 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:4]:W0000 00:00:1721873127.574430 179 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:6]:W0000 00:00:1721873127.581125 182 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:7]:W0000 00:00:1721873127.581122 181 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:1
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:2
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:3
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:4
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:5
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:The average bandwidth of all_reduce with a 4.0GB payload (5 trials, 16 ranks):
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]: algbw: 176.590 GBps (1412.7 Gbps)
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]: busbw: 331.106 GBps (2648.8 Gbps)
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-fbc1:0]:
```

## in Vertex

```
cd a3-mega/vertex/
curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d @/Users/hosseins/projects/a3-bandwidth-test/a3-mega/vertex/nemo/job-payload/nemo-small.json \
     "https://us-east45-aiplatform.googleapis.com/v1/projects/google.com:vertex-training-dlexamples/locations/us-east4/customJobs"
```
