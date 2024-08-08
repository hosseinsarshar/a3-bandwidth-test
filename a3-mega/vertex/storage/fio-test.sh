#!/bin/bash

pip install nvitop

export NCCL_LIB_DIR="/usr/local/nvidia/lib64"
export NCCL_FASTRAK_IFNAME=eth1,eth2,eth3,eth4,eth5,eth6,eth7,eth8
export NCCL_FASTRAK_CTRL_DEV=eth0
export NCCL_SOCKET_IFNAME=eth0
export NCCL_CROSS_NIC=0
export NCCL_ALGO=Ring,Tree
export NCCL_PROTO=Simple
export NCCL_MIN_NCHANNELS=4
export NCCL_P2P_NET_CHUNKSIZE=524288
export NCCL_P2P_PCI_CHUNKSIZE=524288
export NCCL_P2P_NVL_CHUNKSIZE=1048576
export NCCL_FASTRAK_NUM_FLOWS=2
export NCCL_FASTRAK_ENABLE_CONTROL_CHANNEL=0
export NCCL_BUFFSIZE=8388608
export NCCL_FASTRAK_USE_SNAP=1
export NCCL_FASTRAK_USE_LLCM=1
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_NET_GDR_LEVEL=PIX
export NCCL_FASTRAK_ENABLE_HOTPATH_LOGGING=0
export NCCL_TUNER_PLUGIN=libnccl-tuner.so
export NCCL_TUNER_CONFIG_PATH=${NCCL_LIB_DIR}/a3plus_tuner_config.textproto
export NCCL_SHIMNET_GUEST_CONFIG_CHECKER_CONFIG_FILE=${NCCL_LIB_DIR}/a3plus_guest_config.textproto
export NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS=600000
export NCCL_NVLS_ENABLE=0
export TORCH_CPP_LOG_LEVEL=INFO # this is to turn on the verbose torch logs
export TORCH_DISTRIBUTED_DEBUG=DETAIL

# export NCCL_DEBUG=INFO

apt-get update
apt-get install -y fio

git clone https://github.com/stas00/ml-engineering.git
cd ml-engineering/storage

chmod +x ./fio-scan

export path_to_test=/gcs/hosseins-vertex-test/sd/fio-test-$RANK
echo "Participating nodes: $NNODES"
echo "Bandwidth test starts on RANK:$RANK to test PATH:$path_to_test"

./fio-scan $path_to_test

echo "sleep infinity on NODE_RANK:$NODE_RANK"
sleep infinity
echo "Pod on $(hostname --fqdn) is exiting"

# copy one of the yaml config files, like llama2... to the helm folder -> selected-congifuration.yaml

