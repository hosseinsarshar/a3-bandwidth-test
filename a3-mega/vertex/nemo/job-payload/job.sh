#!/bin/bash

function on_script_completion {
    # Note: This semaphore is used to terminate the TCPx side-car
    touch /semaphore/workload_terminated
}

export JOB_IDENTIFIER=nemo-vertex-$CLOUD_ML_JOB_ID

# trap on_script_completion EXIT
echo "Pod on $(hostname --fqdn) is running"
echo "Pod is assigned job index of $JOB_COMPLETION_INDEX"
echo "Job ID is $JOB_IDENTIFIER"

echo "Running nvidia-smi"
nvidia-smi

# mkdir -p /gcs
# gcsfuse --client-protocol http2 $GCS_FUSE_BUCKET /gcs 

# mkdir -p /gcs/index_mapping_dir

# export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/cuda-12.3/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/local/nccl-plugin/lib64:/usr/local/nvidia/lib64/:${LD_LIBRARY_PATH}"
echo "Warning: Set LD_LIBRARY_PATH=$LD_LIBRARY_PATH to override the NCCL library"

ldconfig /usr/local/nvidia/lib64/
echo "Added /usr/local/nvidia/lib64/ to ldconfig:"
ldconfig -p | grep libcuda | sed 's/^/  /'

echo "Contents of /usr/local/nccl-plugin/lib64:"
ls /usr/local/nccl-plugin/lib64 | sed 's/^/  /'

touch $SSD_MOUNT_PATH/hello-from-$HOSTNAME.txt
echo "Local SSD contents (path $SSD_MOUNT_PATH):"; ls $SSD_MOUNT_PATH | sed 's/^/  /'

echo "Downloading GPT vocabulary files"
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json &&\
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt

echo "NeMo configuration file:"                                         
cat /etc/workload-configuration/nemo-configuration.yaml | sed 's/^/| /' 
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

echo "Nsight profiling will go to /gcs/hosseins-vertex-test/$JOB_IDENTIFIER/."
mkdir -p /gcs/hosseins-vertex-test/$JOB_IDENTIFIER/

apt -y update && apt -y install gdb python3.10-dbg

export NODE_RANK=$RANK         
export GPUS_PER_NODE=8                         
echo "Launching Torch distributed as node rank $NODE_RANK out of $NNODES nodes"
for ((LOCAL_RANK=0; LOCAL_RANK <= $((GPUS_PER_NODE - 1)); LOCAL_RANK++)); do
    RANK=$((8*$NODE_RANK + $LOCAL_RANK))
    
    OMP_NUM_THREADS=12 RANK=$RANK LOCAL_RANK=$LOCAL_RANK \
    nsys profile -s none -t nvtx,cuda --capture-range=cudaProfilerApi --capture-range-end=stop \
    -o /gcs/hosseins-vertex-test/$JOB_IDENTIFIER/rank-$RANK \
    --session-new "nemo-rank$RANK" \
    python NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py \
    --config-path="a3-bandwidth-test/a3-mega/vertex/nemo/nemo-configs" \
    --config-name="llama2-7b-fp8.yaml" \
    +trainer.num_nodes="$NNODES" \
    +exp_manager.version="$JOB_IDENTIFIER" \
    ${workload_arguments[@]} &

    echo "Launched rank $RANK with PID $!"
    TORCH_PIDS[$LOCAL_RANK]=$!
done

if [ "$NODE_RANK" -eq "1" ]; then
    echo "Launching nvidia-smi in daemon mode with (20 sec delay)"
    nvidia-smi dmon -d 20 -s pum &
fi

# if [ "$NODE_RANK" -eq "0" ] && { ! [ -z ${EMBEDDED_TENSORBOARD_TARGET} ]; }; then
#     echo "Launching an embedded Tensorboard against log directory $EMBEDDED_TENSORBOARD_TARGET"
#     tensorboard --logdir $EMBEDDED_TENSORBOARD_TARGET &
#     wait # <-- This will indefinitely stall node rank 0
# fi

# Wait for Torch processes (might be problematic if only one fails)
for PID in ${TORCH_PIDS[*]}; do
    echo "Waiting on Torch PID $PID"
    wait $PID
done

echo "Pod on $(hostname --fqdn) is exiting"
