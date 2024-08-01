#!/bin/bash


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
python -c "print('Number of nodes participating: 2')"
echo NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS: $NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS
echo MASTER_ADDR: $MASTER_ADDR
echo LOCAL_RANK: $LOCAL_RANK
echo JOB_COMPLETION_INDEX: $JOB_COMPLETION_INDEX


function on_script_completion {
    # Note: This semaphore is used to terminate the TCPx side-car
    touch /semaphore/workload_terminated
}

export CLOUD_ML_JOB_ID=123
export JOB_IDENTIFIER=nemo-vertex-$CLOUD_ML_JOB_ID

# trap on_script_completion EXIT
echo "Pod on $(hostname --fqdn) is running"
echo "Pod is assigned job index of $JOB_COMPLETION_INDEX"
echo "Job ID is $JOB_IDENTIFIER"

echo "Running nvidia-smi"
nvidia-smi

# mkdir -p /tmp
# gcsfuse --client-protocol http2 $GCS_FUSE_BUCKET /tmp 

# mkdir -p /tmp/index_mapping_dir

# export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/cuda-12.3/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
echo "Warning: Set LD_LIBRARY_PATH=$LD_LIBRARY_PATH to override the NCCL library"

ldconfig /usr/local/nvidia/lib64/
echo "Added /usr/local/nvidia/lib64/ to ldconfig:"
ldconfig -p | grep libcuda | sed 's/^/  /'

echo "Contents of /usr/local/nccl-plugin/lib64:"
ls /usr/local/nccl-plugin/lib64 | sed 's/^/  /'

export SSD_MOUNT_PATH=/tmp/ssd

mkdir -p $SSD_MOUNT_PATH

touch $SSD_MOUNT_PATH/hello-from-$HOSTNAME.txt
echo "Local SSD contents (path $SSD_MOUNT_PATH):"; ls $SSD_MOUNT_PATH | sed 's/^/  /'



echo "Downloading GPT vocabulary files"
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json &&\
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt

git clone https://github.com/hosseinsarshar/a3-bandwidth-test.git

echo "NeMo configuration file:"                                         
cat a3-bandwidth-test/a3-mega/vertex/nemo/nemo-configs/llama2-7b.yaml | sed 's/^/| /' 
echo ""
readarray -d "" workload_arguments < <(env | grep -e "^WORKLOAD_" | sed 's/^WORKLOAD_/+/' | tr '\n' '\0') 
echo "Detected the following additional workload arguments:"            
for workload_argument in "${workload_arguments[@]}"; do                 
    echo "  $workload_argument"                                           
done 

sleep 10 # <- Hack to allow some time for service to boot

mount /tmp -o remount,exec 
chmod -R a+rwx /tmp

echo "Checking for presence of nsys:"                                   
which nsys  

echo "Nsight profiling will go to /tmp/hosseins-vertex-test/$JOB_IDENTIFIER/."
mkdir -p /tmp/hosseins-vertex-test/$JOB_IDENTIFIER/

# apt -y update && apt -y install gdb python3.10-dbg

python -c "import os; print(os.listdir('.'))"

mkdir -p /tmp/logs/
mkdir -p /tmp/exp/
mkdir -p /tmp/nemo-experiments/results
mkdir -p /tmp/index_mapping_dir

export NODE_RANK=$RANK         
export GPUS_PER_NODE=8
export WORLD_SIZE=8
export MASTER_PORT=2222
# export MASTER_ADDR=localhost

echo RANK:$RANK
echo NODE_RANK:$NODE_RANK
echo GPUS_PER_NODE:$GPUS_PER_NODE
echo WORLD_SIZE:$WORLD_SIZE
echo MASTER_PORT:$MASTER_PORT
echo NNODES:$NNODES

echo "Launching Torch distributed as node rank $NODE_RANK out of $NNODES nodes"
for ((LOCAL_RANK=0; LOCAL_RANK <= $((GPUS_PER_NODE - 1)); LOCAL_RANK++)); do
    RANK=$((8*$NODE_RANK + $LOCAL_RANK))
    
    OMP_NUM_THREADS=12 RANK=$RANK LOCAL_RANK=$LOCAL_RANK HYDRA_FULL_ERROR=1 \
    nsys profile -s none -t nvtx,cuda --capture-range=cudaProfilerApi --capture-range-end=stop \
    -o /tmp/hosseins-vertex-test/$JOB_IDENTIFIER/rank-$RANK \
    --session-new "nemo-rank$RANK" \
    python NemoHossein/examples/nlp/language_modeling/megatron_gpt_pretraining.py \
    --config-path="/workspace/a3-bandwidth-test/a3-mega/vertex/nemo/nemo-configs" \
    --config-name="llama2-7b" \
    +trainer.num_nodes="$NNODES" \
    +exp_manager.explicit_log_dir="/tmp/nemo-experiments/results" \
    +model.data.index_mapping_dir="/tmp/index_mapping_dir" \
    +exp_manager.version="$JOB_IDENTIFIER" \
    +exp_manager.exp_dir="/tmp/exp" \
    +model.data.data_prefix="[1.0,gs://northam-ce-mlai-tpu/wikipedia/hfbpe_gpt_training_data_text_document]" \
    > /tmp/logs/rank-$RANK.log 2>&1 &
    # ${workload_arguments[@]} \

    echo "Launched rank $RANK with PID $!"
    echo "Logs are available at /tmp/logs/rank-$RANK.log"
    TORCH_PIDS[$LOCAL_RANK]=$!
done

if [ "$NODE_RANK" -eq "1" ]; then
    echo "Launching nvidia-smi in daemon mode with (20 sec delay)"
    nvidia-smi dmon -d 20 -s pum &
fi

if [ "$NODE_RANK" -eq "0" ] && { ! [ -z ${EMBEDDED_TENSORBOARD_TARGET} ]; }; then
    echo "Launching an embedded Tensorboard against log directory $EMBEDDED_TENSORBOARD_TARGET"
    tensorboard --logdir $EMBEDDED_TENSORBOARD_TARGET &
    wait # <-- This will indefinitely stall node rank 0
fi

# Wait for Torch processes (might be problematic if only one fails)
for PID in ${TORCH_PIDS[*]}; do
    echo "Waiting on Torch PID $PID"
    wait $PID
done

sleep 600

echo "Pod on $(hostname --fqdn) is exiting"

# copy one of the yaml config files, like llama2... to the helm folder -> selected-congifuration.yaml

# DLL Logger
# flags in the llama2-7B yaml file

#
##
###
####
#####
#####
####
###
##
#
#
##
###
####
#####
#####
####
###
##
#

W0000 00:00:1722455981.557457    1804 zone_info_source.cc:122] RAW: Falling back to critical America/Los_Angeles zoneinfo data
[NeMo I 2024-07-31 19:59:50 megatron_gpt_model:1587] Pipeline model parallel rank: 0, Tensor model parallel rank: 0, Number of model parameters on device: 6.89e+09. Number of precise model parameters on device: 6888361984.
[NeMo I 2024-07-31 19:59:50 megatron_gpt_model:1441] Building GPT datasets.
[NeMo I 2024-07-31 19:59:50 utils:47] Let split_matrix = [(0, 0.9), (0.9, 0.98), (0.98, 1.0)]
[NeMo I 2024-07-31 19:59:50 utils:47] Let mock = True, as both blend and blend_per_split are None
[NeMo I 2024-07-31 19:59:50 utils:47] Building dataset splits with cls=MockGPTDataset, sizes=[512000, 65536, 51200], and config=GPTDatasetConfig(random_seed=1234, sequence_length=4096, blend=None, blend_per_split=None, split='90,8,2', split_matrix=[(0, 0.9), (0.9, 0.98), (0.98, 1.0)], num_dataset_builder_threads=1, path_to_cache='/tmp/index_mapping_dir', mmap_bin_files=True, mock=True, tokenizer=<nemo.collections.common.tokenizers.huggingface.auto_tokenizer.AutoTokenizer object at 0x791a44f351e0>, reset_position_ids=False, reset_attention_mask=False, eod_mask_loss=False, create_attention_mask=True, drop_last_partial_validation_sequence=True, add_extra_token_to_sequence=True)
[NeMo I 2024-07-31 19:59:50 utils:47] Build and save the MockGPTDataset train indices
[NeMo I 2024-07-31 19:59:50 utils:47] > total number of samples: 539577
[NeMo I 2024-07-31 19:59:50 utils:47] > total number of epochs: 12
[NeMo I 2024-07-31 19:59:51 utils:47] Build and save the MockGPTDataset valid indices
[NeMo I 2024-07-31 19:59:51 utils:47] > total number of samples: 67626
[NeMo I 2024-07-31 19:59:51 utils:47] > total number of epochs: 17
[rank0]:[E ProcessGroupNCCL.cpp:564] [Rank 0] Some NCCL operations have failed or timed out. Due to the asynchronous nature of CUDA kernels, subsequent GPU operations might run on corrupted/incomplete data.
[rank0]:[E ProcessGroupNCCL.cpp:570] [Rank 0] To avoid data inconsistency, we are taking the entire process down.
[rank0]:[E ProcessGroupNCCL.cpp:1335] [PG 0 Rank 0] NCCL watchdog thread terminated with exception: NCCL error: internal error - please report this issue to the NCCL developers, NCCL version 2.21.5
ncclInternalError: Internal check failed.
Last error:
    @     0x79139d98e78c  ncclNetPluginShim_test()
Exception raised from checkForNCCLErrorsInternal at /opt/pytorch/pytorch/torch/csrc/distributed/c10d/ProcessGroupNCCL.cpp:1695 (most recent call first):
frame #0: c10::Error::Error(c10::SourceLocation, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >) + 0x99 (0x791b6d39bdc9 in /usr/local/lib/python3.10/dist-packages/torch/lib/libc10.so)
frame #1: c10d::ProcessGroupNCCL::checkForNCCLErrorsInternal(std::vector<std::shared_ptr<c10d::NCCLComm>, std::allocator<std::shared_ptr<c10d::NCCLComm> > > const&) + 0x34d (0x791b0bdb193d in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #2: c10d::ProcessGroupNCCL::WorkNCCL::checkAndSetException() + 0x7b (0x791b0bdb1beb in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #3: c10d::ProcessGroupNCCL::watchdogHandler() + 0x219 (0x791b0bdb90a9 in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #4: c10d::ProcessGroupNCCL::ncclCommWatchdog() + 0x125 (0x791b0bdb9ed5 in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #5: <unknown function> + 0xdc253 (0x791b6cab0253 in /lib/x86_64-linux-gnu/libstdc++.so.6)
frame #6: <unknown function> + 0x94ac3 (0x791b874b9ac3 in /lib/x86_64-linux-gnu/libc.so.6)
frame #7: <unknown function> + 0x126850 (0x791b8754b850 in /lib/x86_64-linux-gnu/libc.so.6)

terminate called after throwing an instance of 'c10::DistBackendError'
  what():  [PG 0 Rank 0] NCCL watchdog thread terminated with exception: NCCL error: internal error - please report this issue to the NCCL developers, NCCL version 2.21.5
ncclInternalError: Internal check failed.
Last error:
    @     0x79139d98e78c  ncclNetPluginShim_test()
Exception raised from checkForNCCLErrorsInternal at /opt/pytorch/pytorch/torch/csrc/distributed/c10d/ProcessGroupNCCL.cpp:1695 (most recent call first):
frame #0: c10::Error::Error(c10::SourceLocation, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >) + 0x99 (0x791b6d39bdc9 in /usr/local/lib/python3.10/dist-packages/torch/lib/libc10.so)
frame #1: c10d::ProcessGroupNCCL::checkForNCCLErrorsInternal(std::vector<std::shared_ptr<c10d::NCCLComm>, std::allocator<std::shared_ptr<c10d::NCCLComm> > > const&) + 0x34d (0x791b0bdb193d in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #2: c10d::ProcessGroupNCCL::WorkNCCL::checkAndSetException() + 0x7b (0x791b0bdb1beb in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #3: c10d::ProcessGroupNCCL::watchdogHandler() + 0x219 (0x791b0bdb90a9 in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #4: c10d::ProcessGroupNCCL::ncclCommWatchdog() + 0x125 (0x791b0bdb9ed5 in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #5: <unknown function> + 0xdc253 (0x791b6cab0253 in /lib/x86_64-linux-gnu/libstdc++.so.6)
frame #6: <unknown function> + 0x94ac3 (0x791b874b9ac3 in /lib/x86_64-linux-gnu/libc.so.6)
frame #7: <unknown function> + 0x126850 (0x791b8754b850 in /lib/x86_64-linux-gnu/libc.so.6)

Exception raised from ncclCommWatchdog at /opt/pytorch/pytorch/torch/csrc/distributed/c10d/ProcessGroupNCCL.cpp:1339 (most recent call first):
frame #0: c10::Error::Error(c10::SourceLocation, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >) + 0x99 (0x791b6d39bdc9 in /usr/local/lib/python3.10/dist-packages/torch/lib/libc10.so)
frame #1: <unknown function> + 0xf6f04e (0x791b0bde604e in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #2: <unknown function> + 0xca016a (0x791b0bb1716a in /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so)
frame #3: <unknown function> + 0xdc253 (0x791b6cab0253 in /lib/x86_64-linux-gnu/libstdc++.so.6)
frame #4: <unknown function> + 0x94ac3 (0x791b874b9ac3 in /lib/x86_64-linux-gnu/libc.so.6)
frame #5: <unknown function> + 0x126850 (0x791b8754b850 in /lib/x86_64-linux-gnu/libc.so.6)

[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] *** Process received signal ***
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] Signal: Aborted (6)
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] Signal code:  (-6)
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 0] /lib/x86_64-linux-gnu/libc.so.6(+0x42520)[0x791b87467520]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 1] /lib/x86_64-linux-gnu/libc.so.6(pthread_kill+0x12c)[0x791b874bb9fc]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 2] /lib/x86_64-linux-gnu/libc.so.6(raise+0x16)[0x791b87467476]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 3] /lib/x86_64-linux-gnu/libc.so.6(abort+0xd3)[0x791b8744d7f3]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 4] /lib/x86_64-linux-gnu/libstdc++.so.6(+0xa2b9e)[0x791b6ca76b9e]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 5] /lib/x86_64-linux-gnu/libstdc++.so.6(+0xae20c)[0x791b6ca8220c]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 6] /lib/x86_64-linux-gnu/libstdc++.so.6(+0xae277)[0x791b6ca82277]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 7] /lib/x86_64-linux-gnu/libstdc++.so.6(+0xae1fe)[0x791b6ca821fe]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 8] /usr/local/lib/python3.10/dist-packages/torch/lib/libtorch_cuda.so(+0xca0219)[0x791b0bb17219]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [ 9] /lib/x86_64-linux-gnu/libstdc++.so.6(+0xdc253)[0x791b6cab0253]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [10] /lib/x86_64-linux-gnu/libc.so.6(+0x94ac3)[0x791b874b9ac3]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] [11] /lib/x86_64-linux-gnu/libc.so.6(+0x126850)[0x791b8754b850]
[gke-a3-mega-asia-a3-mega-asia-node-po-c2a38dbc-bgzz:00572] *** End of error message ***
The target application terminated. One or more process it created re-parented.
Waiting for termination of re-parented processes.
Use the `--wait` option to modify this behavior.