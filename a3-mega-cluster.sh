# Link to the setup: 
#        https://cloud.google.com/kubernetes-engine/docs/how-to/gpu-bandwidth-gpudirect-tcpx#create-gke-environment

ZONE=europe-west4-c
REGION=europe-west4
LOCATION=$REGION
POD_IP_ADDRESS_RANGE=10.64.0.0/19
SERVICE_IP_ADDRESS_RANGE=10.65.0.0/19
SOURCE_RANGE=192.168.0.0/16


export PREFIX="tcpxo"
export REGION="europe-west4"
export MTU=8244
export PROJECT=northam-ce-mlai-tpu

export GKE_VERSION=1.29.4-gke.1670000
export CLUSTER_NAME="a3-mega-tcpxo"

NODE_POOL_NAME=$CLUSTER_NAME-node-pool


for N in $(seq 8 8); do
  SUBNET_RANGE=192.168.$N.0/24
  echo $SUBNET_RANGE

  gcloud compute --project=${PROJECT} \
    networks create \
    ${PREFIX?}-net-$N \
    --subnet-mode=custom \
    --mtu=${MTU}

  gcloud compute --project=${PROJECT} \
    networks subnets create \
    ${PREFIX?}-sub-$N \
    --network=${PREFIX?}-net-$N \
    --region=${REGION?} \
    --range=$SUBNET_RANGE

  gcloud compute --project=${PROJECT} \
    firewall-rules create \
    ${PREFIX?}-internal-$N \
    --network=${PREFIX?}-net-$N \
    --action=ALLOW \
    --rules=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=192.168.0.0/16
done

gcloud container get-server-config --format="yaml(validMasterVersions)" --zone=${ZONE} --project=${PROJECT}


gcloud --project ${PROJECT} beta container clusters create ${CLUSTER_NAME} \
     --enable-dataplane-v2 --enable-ip-alias --region ${REGION} \
     --node-locations ${ZONE} --enable-multi-networking \
     --cluster-version ${GKE_VERSION} --no-enable-autoupgrade


export NODE_POOL_NAME="a3plus-multi-nic"
export MACHINE_TYPE="a3-megagpu-8g" 
export NODE_COUNT=2
export ACCELERATOR_ARG="type=nvidia-h100-mega-80gb,count=8,gpu-driver-version=latest"

gcloud beta container node-pools create ${NODE_POOL_NAME} --region ${REGION} --node-locations ${ZONE} --cluster ${CLUSTER_NAME} --project ${PROJECT} --no-enable-autoupgrade --accelerator ${ACCELERATOR_ARG} --machine-type ${MACHINE_TYPE} --num-nodes ${NODE_COUNT} --additional-node-network network=${PREFIX}-net-1,subnetwork=${PREFIX}-sub-1 --additional-node-network network=${PREFIX}-net-2,subnetwork=${PREFIX}-sub-2 --additional-node-network network=${PREFIX}-net-3,subnetwork=${PREFIX}-sub-3 --additional-node-network network=${PREFIX}-net-4,subnetwork=${PREFIX}-sub-4 --additional-node-network network=${PREFIX}-net-5,subnetwork=${PREFIX}-sub-5 --additional-node-network network=${PREFIX}-net-6,subnetwork=${PREFIX}-sub-6 --additional-node-network network=${PREFIX}-net-7,subnetwork=${PREFIX}-sub-7 --additional-node-network network=${PREFIX}-net-8,subnetwork=${PREFIX}-sub-8 --enable-gvnic --scopes "https://www.googleapis.com/auth/cloud-platform"

kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml

kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/nccl-tcpxo-installer.yaml

kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/nccl-test.yaml

kubectl exec --stdin --tty --container=nccl-test nccl-test-host-1 -- /scripts/allgather.sh nccl-host-1 nccl-host-2


#                                                              out-of-place                       in-place          
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)       
           0             0     float    none      -1     0.27    0.00    0.00      0     0.20    0.00    0.00      0
           0             0     float    none      -1     0.19    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.17    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.18    0.00    0.00      0
           0             0     float    none      -1     0.17    0.00    0.00      0     0.18    0.00    0.00      0
         256             4     float    none      -1    190.7    0.00    0.00      0    196.3    0.00    0.00      0
         512             8     float    none      -1    189.2    0.00    0.00      0    188.2    0.00    0.00      0
        1024            16     float    none      -1    189.7    0.01    0.01      0    187.4    0.01    0.01      0
        2048            32     float    none      -1    189.2    0.01    0.01      0    188.7    0.01    0.01      0
        4096            64     float    none      -1    190.2    0.02    0.02      0    189.4    0.02    0.02      0
        8192           128     float    none      -1    190.3    0.04    0.04      0    190.3    0.04    0.04      0
       16384           256     float    none      -1    194.4    0.08    0.08      0    194.9    0.08    0.08      0
       32768           512     float    none      -1    193.9    0.17    0.16      0    193.3    0.17    0.16      0
       65536          1024     float    none      -1    196.0    0.33    0.31      0    196.5    0.33    0.31      0
      131072          2048     float    none      -1    221.6    0.59    0.55      0    233.5    0.56    0.53      0
      262144          4096     float    none      -1    242.9    1.08    1.01      0    239.1    1.10    1.03      0
      524288          8192     float    none      -1    246.8    2.12    1.99      0    243.3    2.16    2.02      0
     1048576         16384     float    none      -1    301.6    3.48    3.26      0    294.4    3.56    3.34      0
     2097152         32768     float    none      -1    293.4    7.15    6.70      0    298.2    7.03    6.59      0
     4194304         65536     float    none      -1    318.6   13.17   12.34      0    307.5   13.64   12.79      0
     8388608        131072     float    none      -1    332.4   25.23   23.66      0    324.0   25.89   24.27      0
    16777216        262144     float    none      -1    381.8   43.94   41.20      0    383.2   43.79   41.05      0
    33554432        524288     float    none      -1    479.6   69.97   65.59      0    467.6   71.76   67.27      0
    67108864       1048576     float    none      -1    655.6  102.37   95.97      0    673.1   99.71   93.47      0
   134217728       2097152     float    none      -1   1041.8  128.83  120.78      0   1058.4  126.81  118.89      0
   268435456       4194304     float    none      -1   2784.3   96.41   90.38      0   1688.3  159.00  149.06      0
   536870912       8388608     float    none      -1   2910.0  184.49  172.96      0   4120.5  130.29  122.15      0
  1073741824      16777216     float    none      -1   6101.8  175.97  164.97      0   6933.3  154.87  145.19      0
  2147483648      33554432     float    none      -1    11852  181.20  169.87      0    10804  198.77  186.35      0
  4294967296      67108864     float    none      -1    21990  195.32  183.11      0    22999  186.74  175.07      0
  8589934592     134217728     float    none      -1    44150  194.56  182.40      0    44420  193.38  181.29      0