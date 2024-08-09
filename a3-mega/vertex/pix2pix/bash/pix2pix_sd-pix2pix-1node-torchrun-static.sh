#!/bin/bash

python -c "print('******* All Reduce Network Benchmark Starts *******')"

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

#install nvtop for debugging
pip install nvitop

# Debug NCCL
#export NCCL_DEBUG=INFO

python -c "print('Number of nodes participating: 1')"
echo NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: $NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS
echo MASTER_ADDR: $MASTER_ADDR
echo MASTER_PORT: $MASTER_PORT
echo LOCAL_RANK: $LOCAL_RANK
echo JOB_COMPLETION_INDEX: $JOB_COMPLETION_INDEX

# Job info
date +"%Y%m%d_%H"
RUNDATE=$(date +"%Y%m%d%H")
export CLOUD_ML_JOB_ID="${CLOUD_ML_JOB_ID:=RUNDATE}" 
export JOB_IDENTIFIER=sd-pix2pix-1node-$CLOUD_ML_JOB_ID

# update config for # of nodes
#/opt/conda/bin/accelerate config update --config_file ./trainer/accelerate-files/2host_config.yaml

export MODEL_NAME="/gcs/dlexamples-shared-data/diffusers-pix2pix/models--runwayml--stable-diffusion-v1-5"
# export MODEL_NAME="gs://dlexamples-shared-data/diffusers-pix2pix/models--runwayml--stable-diffusion-v1-5"
export MODEL_PATH="./local_model_path"
export DATASET_ID="/gcs/dlexamples-shared-data/diffusers-pix2pix/datasets--timbrooks--instructpix2pix-clip-filtered/preprocessed"
export CACHE_DIR="/tmp/sd-pix2pix-cache"
export OUTPUT_DIR="/tmp/sd-pix2pix-output"

mkdir -p $MODEL_PATH
gsutil -m cp -r $MODEL_NAME $MODEL_PATH
cp -r $MODEL_NAME $MODEL_PATH

mkdir -p /tmp/localssd/$CACHE_DIR
chmod 777 -R /tmp/localssd/$CACHE_DIR
mkdir -p /tmp/localssd/$OUTPUT_DIR
chmod 777 -R /tmp/localssd/$OUTPUT_DIR

pip install torchvision
pip install datasets
pip install ftfy
pip install tensorboard
pip install xformers

export DATASET_ID="/gcs/dlexamples-shared-data/diffusers-pix2pix/dataset_5000"


chmod +x -R diffusers
OMP_NUM_THREADS=12 torchrun --nnodes=1 \
    --nproc-per-node=8 \
    --standalone \
    a3-bandwidth-test/a3-mega/vertex/pix2pix/code/train_instruct_pix2pix.py \
    --pretrained_model_name_or_path=$MODEL_NAME \
    --dataset_name=$DATASET_ID \
    --dataloader_num_workers=20 \
    --use_ema \
    --cache_dir=$CACHE_DIR \
    --output_dir=$OUTPUT_DIR \
    --streaming=true \
    --enable_xformers_memory_efficient_attention \
    --resolution=256 --random_flip \
    --train_batch_size=4 --gradient_accumulation_steps=4 --gradient_checkpointing \
    --max_train_steps=100 \
    --checkpointing_steps=1000 --checkpoints_total_limit=1 \
    --learning_rate=5e-05 --lr_warmup_steps=0 \
    --conditioning_dropout_prob=0.05 \
    --mixed_precision=fp16 \
    --original_image_column=original_image \
    --seed=42

chmod +x -R diffusers
torchrun --nnodes=1 \
    --nproc-per-node=8 \
    --standalone \
    a3-bandwidth-test/a3-mega/vertex/pix2pix/code/train_instruct_pix2pix.py \
    --pretrained_model_name_or_path=$MODEL_NAME \
    --train_data_dir=$DATASET_ID \
    --dataloader_num_workers=20 \
    --use_ema \
    --cache_dir=$CACHE_DIR \
    --output_dir=$OUTPUT_DIR \
    --enable_xformers_memory_efficient_attention \
    --resolution=256 --random_flip \
    --train_batch_size=4 --gradient_accumulation_steps=4 --gradient_checkpointing \
    --max_train_steps=1000 \
    --checkpointing_steps=1000 --checkpoints_total_limit=1 \
    --learning_rate=5e-05 --lr_warmup_steps=0 \
    --conditioning_dropout_prob=0.05 \
    --mixed_precision=fp16 \
    --original_image_column=image \
    --seed=42

train_instruct_pix2pix.py: error: unrecognized arguments: -- =20 --use_ema --cache_dir=/tmp/sd-pix2pix-cache --output_dir=/tmp/sd-pix2pix-output --enable_xfor
mers_memory_efficient_attention --resolution=256 --random_flip --train_batch_size=4 --gradient_accumulation_steps=4 --gradient_checkpointing --max_train_steps
=1000 --checkpointing_steps=1000 --checkpoints_total_limit=1 --learning_rate=5e-05 --lr_warmup_steps=0 --conditioning_dropout_prob=0.05 --mixed_precision=fp16
 --original_image_column=original_image --seed=42                                                                                                             


echo "sleep infinity on NODE_RANK:$RANK"
sleep infinity
