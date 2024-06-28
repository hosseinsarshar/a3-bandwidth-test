# Link to the setup: 
#        https://cloud.google.com/kubernetes-engine/docs/how-to/gpu-bandwidth-gpudirect-tcpx#create-gke-environment

PROJECT_ID=northam-ce-mlai-tpu
ZONE=europe-west4-c
REGION=europe-west4
LOCATION=$REGION 
CLUSTER_NAME=a3-cluster
POD_IP_ADDRESS_RANGE=10.64.0.0/19
SERVICE_IP_ADDRESS_RANGE=10.65.0.0/19
SOURCE_RANGE=192.168.0.0/16
NODE_POOL_NAME=$CLUSTER_NAME-node-pool

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE

# create network and subnet:
gcloud compute networks create $CLUSTER_NAME-network --subnet-mode=custom

gcloud compute networks subnets create $CLUSTER_NAME-subnet \
    --network=$CLUSTER_NAME-network \
    --region=$REGION \
    --range=10.10.0.0/24

gcloud compute networks subnets update $CLUSTER_NAME-subnet \
    --region=$REGION \
    --add-secondary-ranges="$CLUSTER_NAME-pods=$POD_IP_ADDRESS_RANGE,$CLUSTER_NAME-services=$SERVICE_IP_ADDRESS_RANGE"

for N in $(seq 1 4); do
  SUBNET_RANGE=192.168.$N.0/24
  echo $SUBNET_RANGE
  gcloud compute networks create $CLUSTER_NAME-net-$N \
      --subnet-mode=custom \
      --mtu=8244

  gcloud compute networks subnets create $CLUSTER_NAME-sub-$N \
      --network=$CLUSTER_NAME-net-$N \
      --region=$REGION \
      --range=$SUBNET_RANGE

  gcloud compute firewall-rules create $CLUSTER_NAME-internal-$N \
    --network=$CLUSTER_NAME-net-$N \
    --action=ALLOW \
    --rules=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=$SOURCE_RANGE
done

## If you want to delete the network footprints
# for N in $(seq 1 4); do
# gcloud compute networks delete $$CLUSTER_NAME-net-$N
# 
# gcloud compute networks subnets delete $$CLUSTER_NAME-sub-$N \
#     --region=$REGION
# 
# gcloud compute firewall-rules delete $$CLUSTER_NAME-internal-$N
# done

## Install kubectl if needed
# gcloud components install kubectl
# kubectl version --client
# gcloud components install gke-gcloud-auth-plugin

# Get the list of supported gke systems
hosseins$ gcloud container get-server-config --format="yaml(validMasterVersions)" --zone=${ZONE} --project=${PROJECT_ID}

## Create the GKE Cluster
# 1.27.11-gke.1062000, 1.29.5-gke.1091000

gcloud container clusters create $CLUSTER_NAME \
    --location=$REGION \
    --cluster-version=1.29.5-gke.1121000 \
    --network=$CLUSTER_NAME-network \
    --subnetwork=$CLUSTER_NAME-subnet \
    --enable-dataplane-v2 --enable-ip-alias \
    --enable-multi-networking \
    --no-enable-autoupgrade \
    --cluster-secondary-range-name=$CLUSTER_NAME-pods \
    --services-secondary-range-name=$CLUSTER_NAME-services

gcloud container clusters get-credentials $CLUSTER_NAME \
    --region=$REGION

kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: Network
metadata:
  name: vpc1
spec:
  parametersRef:
    group: networking.gke.io
    kind: GKENetworkParamSet
    name: vpc1
  type: Device
---
apiVersion: networking.gke.io/v1
kind: Network
metadata:
  name: vpc2
spec:
  parametersRef:
    group: networking.gke.io
    kind: GKENetworkParamSet
    name: vpc2
  type: Device
---
apiVersion: networking.gke.io/v1
kind: Network
metadata:
  name: vpc3
spec:
  parametersRef:
    group: networking.gke.io
    kind: GKENetworkParamSet
    name: vpc3
  type: Device
---
apiVersion: networking.gke.io/v1
kind: Network
metadata:
  name: vpc4
spec:
  parametersRef:
    group: networking.gke.io
    kind: GKENetworkParamSet
    name: vpc4
  type: Device
---
apiVersion: networking.gke.io/v1
kind: GKENetworkParamSet
metadata:
  name: vpc1
spec:
  vpc: $CLUSTER_NAME-net-1
  vpcSubnet: $CLUSTER_NAME-sub-1
  deviceMode: NetDevice
---
apiVersion: networking.gke.io/v1
kind: GKENetworkParamSet
metadata:
  name: vpc2
spec:
  vpc: $CLUSTER_NAME-net-2
  vpcSubnet: $CLUSTER_NAME-sub-2
  deviceMode: NetDevice
---
apiVersion: networking.gke.io/v1
kind: GKENetworkParamSet
metadata:
  name: vpc3
spec:
  vpc: $CLUSTER_NAME-net-3
  vpcSubnet: $CLUSTER_NAME-sub-3
  deviceMode: NetDevice
---
apiVersion: networking.gke.io/v1
kind: GKENetworkParamSet
metadata:
  name: vpc4
spec:
  vpc: $CLUSTER_NAME-net-4
  vpcSubnet: $CLUSTER_NAME-sub-4
  deviceMode: NetDevice
EOF

## Creating Node Pools

gcloud container node-pools create $NODE_POOL_NAME \
    --cluster=$CLUSTER_NAME \
    --location=$REGION \
    --node-locations=$ZONE \
    --machine-type=a3-highgpu-8g \
    --disk-size=500GB \
    --num-nodes=2 \
    --accelerator=type=nvidia-h100-80gb,count=8,gpu-driver-version=LATEST \
    --additional-node-network=network=$CLUSTER_NAME-net-1,subnetwork=$CLUSTER_NAME-sub-1 \
    --additional-node-network=network=$CLUSTER_NAME-net-2,subnetwork=$CLUSTER_NAME-sub-2 \
    --additional-node-network=network=$CLUSTER_NAME-net-3,subnetwork=$CLUSTER_NAME-sub-3 \
    --additional-node-network=network=$CLUSTER_NAME-net-4,subnetwork=$CLUSTER_NAME-sub-4 \
    --enable-gvnic \
    --no-enable-autoupgrade \
    --ephemeral-storage-local-ssd=count=16

gcloud beta container node-pools create ${NODE_POOL_NAME} --region ${REGION} --node-locations ${ZONE} --cluster ${CLUSTER_NAME} --project ${PROJECT} --no-enable-autoupgrade --accelerator ${ACCELERATOR_ARG} --machine-type ${MACHINE_TYPE} --num-nodes ${NODE_COUNT} --additional-node-network network=${PREFIX}-net-1,subnetwork=${PREFIX}-sub-1 --additional-node-network network=${PREFIX}-net-2,subnetwork=${PREFIX}-sub-2 --additional-node-network network=${PREFIX}-net-3,subnetwork=${PREFIX}-sub-3 --additional-node-network network=${PREFIX}-net-4,subnetwork=${PREFIX}-sub-4 --additional-node-network network=${PREFIX}-net-5,subnetwork=${PREFIX}-sub-5 --additional-node-network network=${PREFIX}-net-6,subnetwork=${PREFIX}-sub-6 --additional-node-network network=${PREFIX}-net-7,subnetwork=${PREFIX}-sub-7 --additional-node-network network=${PREFIX}-net-8,subnetwork=${PREFIX}-sub-8 --enable-gvnic --scopes "https://www.googleapis.com/auth/cloud-platform"

gcloud beta container node-pools create $NODE_POOL_NAME \
    --cluster=$CLUSTER_NAME \
    --location=$REGION \
    --node-locations=$ZONE \
    --machine-type=a3-highgpu-8g \
    --disk-size=500GB \
    --num-nodes=2 \
    --accelerator=type=nvidia-h100-80gb,count=8,gpu-driver-version=LATEST \
    --additional-node-network=network=$CLUSTER_NAME-net-1,subnetwork=$CLUSTER_NAME-sub-1 \
    --additional-node-network=network=$CLUSTER_NAME-net-2,subnetwork=$CLUSTER_NAME-sub-2 \
    --additional-node-network=network=$CLUSTER_NAME-net-3,subnetwork=$CLUSTER_NAME-sub-3 \
    --additional-node-network=network=$CLUSTER_NAME-net-4,subnetwork=$CLUSTER_NAME-sub-4 \
    --enable-gvnic \
    --no-enable-autoupgrade \
    --ephemeral-storage-local-ssd=count=16 \
    --preemptible

gcloud container operations list --region $REGION --filter="clusterName=a3-cluster"

gcloud beta container node-pools delete ${NODE_POOL_NAME} --region ${REGION} --cluster ${CLUSTER_NAME} --project ${PROJECT_ID}

gcloud beta container clusters delete $CLUSTER_NAME  --location=$REGION

gcloud container operations cancel  --region ${REGION} "operation-1718375970828-645dd174-44eb-4a90-aa52-396004714b12"

gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}

## Set up the NCCL-TCPx by deploying the DaemonSet

kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpx/nccl-tcpx-installer.yaml

## Check the status of the DaemonSet Pods

kubectl get pods -n=kube-system -l=name=nccl-tcpx-installer

### The result should look like this:
####  nccl-tcpx-installer-6c2pv                    1/1     Running   0          2m11s
####  nccl-tcpx-installer-qgg82                    1/1     Running   0          2m11s


