#!/bin/bash

python -c "print('******* All Reduce Network Benchmark Starts *******')"
rm -f /usr/share/all_reduce_benchmarks/workload_terminated
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
# export TORCH_CPP_LOG_LEVEL=INFO # this is to turn on the verbose torch logs
# export TORCH_DISTRIBUTED_DEBUG=DETAIL

python -c "print('Number of nodes participating: 2')"
echo NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: $NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS
echo MASTER_ADDR: $(if [[ $RANK -gt 0 ]]; then echo $MASTER_ADDR;else echo localhost;fi)
echo MASTER_PORT: $MASTER_PORT

export NODE_RANK=$RANK         
export GPUS_PER_NODE=8
export WORLD_SIZE=$((NNODES * GPUS_PER_NODE))
export MASTER_PORT=2222
export GLOBAL_BATCH_SIZE=$((WORLD_SIZE*2))
# export MASTER_ADDR=localhost

# echo "sleep for 60 seconds"
# sleep 60

echo RANK:$RANK
echo NODE_RANK:$NODE_RANK
echo GPUS_PER_NODE:$GPUS_PER_NODE
echo WORLD_SIZE:$WORLD_SIZE
echo MASTER_PORT:$MASTER_PORT
echo NNODES:$NNODES

# python -c "import os; [print('{0}: {1}'.format(name, value)) for name, value in os.environ.items()]" # this is to pring all the environment variables
sleep 10

git clone https://github.com/hosseinsarshar/ml-engineering.git ml-eng

# torchrun --rdzv_backend c10d --rdzv_id $CLOUD_ML_JOB_ID --nnodes 2 --nproc_per_node 8 --rdzv_endpoint=$(if [[ $RANK -gt 0 ]]; then echo $MASTER_ADDR;else echo localhost;fi):$MASTER_PORT ml-eng/network/benchmarks/all_reduce_bench.py 

echo "Launching All Reduce dist. run as node rank $NODE_RANK out of $NNODES nodes"

OMP_NUM_THREADS=12 RANK=$RANK \
torchrun  --nproc_per_node=${GPUS_PER_NODE} \
    --nnodes=${NNODES} \
    --rdzv-backend=static \
    --node_rank=$RANK \
    --rdzv_id $CLOUD_ML_JOB_ID \
    --rdzv_endpoint=$(if [[ $RANK -gt 0 ]]; then echo $MASTER_ADDR;else echo localhost;fi):$MASTER_PORT \
    ml-eng/network/benchmarks/all_reduce_bench.py

# python -u -m torch.distributed.run \
#     --nproc_per_node 8 \
#     --nnodes 2 \
#     --rdzv_endpoint $MASTER_ADDR:$MASTER_PORT \
#     --rdzv_backend c10d \
#     --max_restarts 0 \
#     --role `hostname -s`: \
#     --tee 3 \
#     ml-eng/network/benchmarks/all_reduce_bench.py

echo "Launching All Reduce dist. run as node rank $NODE_RANK out of $NNODES nodes"

OMP_NUM_THREADS=12 RANK=$RANK \
torchrun  --nproc_per_node=${GPUS_PER_NODE} \
    --nnodes=${NNODES} \
    --rdzv-backend=static \
    --node_rank=$RANK \
    --rdzv_id $CLOUD_ML_JOB_ID \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    ml-eng/network/benchmarks/all_reduce_bench.py