git clone https://github.com/mlcommons/training.git

apt-get update
apt-get install unzip

curl https://rclone.org/install.sh | sudo bash
rclone --version

git clone https://github.com/mlperf/logging.git mlperf-logging
pip install -e mlperf-logging

pip install lightning

cd training/stable_diffusion

mkdir /workspace/results

scripts/datasets/coco2014-validation-download-prompts.sh --output-dir /workspace/datasets/coco2014
scripts/datasets/coco2014-validation-download-stats.sh --output-dir /workspace/datasets/coco2014

scripts/checkpoints/download_sd.sh --output-dir /workspace/checkpoints/sd
scripts/checkpoints/download_inception.sh --output-dir /workspace/checkpoints/inception
scripts/checkpoints/download_clip.sh --output-dir /workspace/checkpoints/clip

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
export LD_LIBRARY_PATH=\"${NCCL_LIB_DIR}:${LD_LIBRARY_PATH}:/usr/local/cuda-12.4/:${NCCL_LIB_DIR}/libcuda.so.1\"


export TORCH_CPP_LOG_LEVEL=INFO # this is to turn on the verbose torch logs
export TORCH_DISTRIBUTED_DEBUG=DETAIL



./run_and_time.sh \
  --num-nodes 1 \
  --gpus-per-node 8 \
  --checkpoint /workspace/checkpoints/sd/512-base-ema.ckpt \
  --results-dir /workspace/results \
  --config /workspace/a3-bandwidth-test/a3-mega/vertex/mlcommons/configs/train_01x08x08.yaml