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

# Debug NCCL
export NCCL_DEBUG=INFO

python -c "print('Number of nodes participating: 2')"
echo NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: $NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS
echo MASTER_ADDR: $MASTER_ADDR
echo MASTER_PORT: $MASTER_PORT

# update config for # of nodes
#/opt/conda/bin/accelerate config update --config_file ./trainer/accelerate-files/2host_config.yaml

export MODEL_NAME="./trainer/models--stabilityai--stable-diffusion-3-medium-diffusers"
export INSTANCE_DIR="./trainer/dog"
export OUTPUT_DIR="/tmp/sd3-output"

chmod +x -R diffusers
torchrun --nnodes=2 \
    --nproc-per-node=8 \
    --max-restarts=3 \
    --rdzv-id=sd3-2node-torchrun \
    --rdzv-backend=c10d \
    --rdzv-endpoint=$(if [[ $RANK -gt 0 ]]; then echo $MASTER_ADDR;else echo localhost;fi):$MASTER_PORT \
  diffusers/examples/dreambooth/train_dreambooth_sd3.py \
  --pretrained_model_name_or_path=$MODEL_NAME  \
  --instance_data_dir=$INSTANCE_DIR \
  --output_dir=$OUTPUT_DIR \
  --mixed_precision="fp16" \
  --instance_prompt="a photo of sks dog" \
  --resolution=1024 \
  --train_batch_size=1 \
  --gradient_accumulation_steps=4 \
  --learning_rate=1e-4 \
  --lr_scheduler="constant" \
  --lr_warmup_steps=0 \
  --max_train_steps=500 \
  --validation_prompt="A photo of sks dog in a bucket" \
  --validation_epochs=25 \
  --seed="0"