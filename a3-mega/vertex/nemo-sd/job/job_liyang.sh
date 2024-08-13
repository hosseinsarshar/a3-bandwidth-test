
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
export LD_LIBRARY_PATH=\"${NCCL_LIB_DIR}:${LD_LIBRARY_PATH}:/usr/local/cuda-12.4/:${NCCL_LIB_DIR}/libcuda.so.1\"


export TORCH_CPP_LOG_LEVEL=INFO # this is to turn on the verbose torch logs
export TORCH_DISTRIBUTED_DEBUG=DETAIL

export TORCH_LOGS="+dynamo"
export TORCHDYNAMO_VERBOSE=1


cd /workspace

# export NCCL_DEBUG=INFO

python -c "print('Number of nodes participating: 2')"
echo NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: $NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS
echo MASTER_ADDR: $MASTER_ADDR
echo LOCAL_RANK: $LOCAL_RANK
echo JOB_COMPLETION_INDEX: $JOB_COMPLETION_INDEX

echo Copying files from gcs to local SSD:

mkdir -p ./gcs-sd

echo Copying SD Checkpoint:
cp -r /gcs/hosseins-vertex-test/sd/sd ./gcs-sd/sd

echo Copying CLIP Model:
cp -r /gcs/hosseins-vertex-test/sd/clip ./gcs-sd/clip

export JOB_IDENTIFIER=nemo-vertex-$CLOUD_ML_JOB_ID

export SSD_MOUNT_PATH=/tmp/ssd

mkdir -p $SSD_MOUNT_PATH

# export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/cuda-12.3/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
echo "Warning: Set LD_LIBRARY_PATH=$LD_LIBRARY_PATH to override the NCCL library"

ldconfig /usr/local/nvidia/lib64/
echo "Added /usr/local/nvidia/lib64/ to ldconfig:"
ldconfig -p | grep libcuda | sed 's/^/  /'

git clone https://github.com/hosseinsarshar/a3-bandwidth-test.git

apt -y update && apt -y install gdb python3.10-dbg

pip install "transformers>=4.36.0,<=4.40.2"
pip install huggingface-hub==0.23.2

cd /workspace/a3-bandwidth-test/a3-mega/vertex/nemo-sd/scripts/

python -c "
from mlperf_logging.mllog import constants
from mlperf_logging_utils import mllogger
mllogger.event(key=constants.CACHE_CLEAR, value=True)"

cd /workspace

cd a3-bandwidth-test/a3-mega/vertex/nemo-sd/scripts/
git apply nemo_mlperf.patch

OMP_NUM_THREADS=12 HYDRA_FULL_ERROR=1 \
python /workspace/a3-bandwidth-test/a3-mega/vertex/nemo-sd/scripts/main.py \
    --config-path="/workspace/a3-bandwidth-test/a3-mega/vertex/nemo-sd/configs" \
    --config-name="lyiang-selected-config.yaml" \
    +exp_manager.version="$JOB_IDENTIFIER" \
    +exp_manager.exp_dir="/nemo-experiments/" \
    ++trainer.max_steps=200 \
    ++trainer.log_every_n_steps=1 \
    model.data.synthetic_data=True \
    trainer.devices=1 \
    +trainer.num_nodes=1 \
    model.global_batch_size=128
