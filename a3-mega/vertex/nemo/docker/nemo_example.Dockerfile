FROM nvcr.io/nvidia/nemo:24.05
#FROM nvcr.io/nvidia/nemo:24.03.01.framework
WORKDIR /workspace

# GCSfuse components (used to provide shared storage, not intended for high performance)
RUN apt-get update && apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && echo "deb https://packages.cloud.google.com/apt gcsfuse-buster main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install --yes gcsfuse \
  && apt-get install --yes google-cloud-cli \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && mkdir /gcs

RUN pip install git+https://github.com/NVIDIA/dllogger#egg=dllogger

# COPY enable-step-times-2405.patch /opt/NeMo/enable-step-times-2405.patch
# RUN cd /opt/NeMo/ && git apply enable-step-times-2405.patch 

RUN git clone https://github.com/hosseinsarshar/NeMo.git NemoHossein

ENV NCCL_LIB_DIR="/usr/local/nvidia/lib64"
ENV NCCL_FASTRAK_IFNAME=eth1,eth2,eth3,eth4,eth5,eth6,eth7,eth8
ENV NCCL_FASTRAK_CTRL_DEV=eth0
ENV NCCL_SOCKET_IFNAME=eth0
ENV NCCL_CROSS_NIC=0
ENV NCCL_ALGO=Ring,Tree
ENV NCCL_PROTO=Simple
ENV NCCL_MIN_NCHANNELS=4
ENV NCCL_P2P_NET_CHUNKSIZE=524288
ENV NCCL_P2P_PCI_CHUNKSIZE=524288
ENV NCCL_P2P_NVL_CHUNKSIZE=1048576
ENV NCCL_FASTRAK_NUM_FLOWS=2
ENV NCCL_FASTRAK_ENABLE_CONTROL_CHANNEL=0
ENV NCCL_BUFFSIZE=8388608
ENV NCCL_FASTRAK_USE_SNAP=1
ENV NCCL_FASTRAK_USE_LLCM=1
ENV CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
ENV NCCL_NET_GDR_LEVEL=PIX
ENV NCCL_FASTRAK_ENABLE_HOTPATH_LOGGING=0
ENV NCCL_TUNER_PLUGIN=libnccl-tuner.so
ENV NCCL_TUNER_CONFIG_PATH=${NCCL_LIB_DIR}/a3plus_tuner_config.textproto
ENV NCCL_SHIMNET_GUEST_CONFIG_CHECKER_CONFIG_FILE=${NCCL_LIB_DIR}/a3plus_guest_config.textproto
ENV NCCL_FASTRAK_PLUGIN_ACCEPT_TIMEOUT_MS=600000
ENV NCCL_NVLS_ENABLE=0

# Install launch scripts
# ARG LAUNCHER_COMMIT
# RUN git clone https://github.com/NVIDIA/NeMo-Framework-Launcher.git && \
#     cd NeMo-Framework-Launcher && \
#     git pull && \
#     if [ ! -z $LAUNCHER_COMMIT ]; then \
#         git fetch origin $LAUNCHER_COMMIT && \
#         git checkout FETCH_HEAD; \
#     fi && \
#     pip install --no-cache-dir -r requirements.txt
# 
# ENV LAUNCHER_SCRIPTS_PATH=/opt/NeMo-Framework-Launcher/launcher_scripts
# ENV PYTHONPATH=/opt/NeMo-Framework-Launcher/launcher_scripts:${PYTHONPATH}
# 
# # HF cache
# RUN python -c "from transformers import AutoTokenizer; tok_gpt=AutoTokenizer.from_pretrained('gpt2'); tok_bert=AutoTokenizer.from_pretrained('bert-base-cased'); tok_large_bert=AutoTokenizer.from_pretrained('bert-large-cased'); tok_large_uncased_bert=AutoTokenizer.from_pretrained('bert-large-uncased');"
# 
# # Setup SSH config to allow mpi-operator to communicate with containers in k8s
# RUN echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
#     sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config && \
#     sed -i 's/#   StrictHostKeyChecking ask/    StrictHostKeyChecking no/' /etc/ssh/ssh_config && \
#     mkdir -p /var/run/sshd
# 
# # Examples
# WORKDIR /workspace
# #COPY any user-facing example scripts should go in here
# RUN chmod -R a+w /workspace
# 
# ARG NVIDIA_BUILD_ID
# ENV NVIDIA_BUILD_ID ${NVIDIA_BUILD_ID:-<unknown>}
# LABEL com.nvidia.build.id="${NVIDIA_BUILD_ID}"
# ARG NVIDIA_BUILD_REF
# LABEL com.nvidia.build.ref="${NVIDIA_BUILD_REF}"


