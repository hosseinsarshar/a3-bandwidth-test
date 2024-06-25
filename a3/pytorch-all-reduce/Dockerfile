FROM us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu121.py310

ENV TZ=America/Los_Angeles
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

# RUN pip install torch>=2.1.0

ENV NETRC=/root/.netrc
ENV TRITON_CACHE_DIR=/root/
ENV CUDA_HOME=/usr/local/cuda

# NOTE(mgharbi): adapted from rayproject/ray base image, main libraries needed to run Ray + a few extras
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y \
        sudo tzdata \
        git \
        libjemalloc-dev \
        wget \
        cmake \
        g++ \ 
        zlib1g-dev \
        tmux \
        screen \
        rsync \
        netbase \
        openssh-client \
        gnupg \
        emacs-nox \
        ssh-client \
        vim \
        zsh \
        git \
        locales \
        rsync \
        curl \
        tree \
        htop \
        libaio-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN conda install -y libgcc-ng \
    && conda install -y -c conda-forge libffi=3.4.2 \
    && conda clean -y --all \
    && pip install --no-cache-dir \
        flatbuffers \
        cython==0.29.37 \
        # Necessary for Dataset to work properly.
        numpy\>=1.20 \
        psutil \
    # To avoid the following error on Jenkins:
    # AttributeError: 'numpy.ufunc' object has no attribute '__module__'
    && pip uninstall -y dask \ 
    # We install cmake temporarily to get psutil
    && apt-get autoremove -y cmake zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && pip --no-cache-dir install \
    "ray[all]==2.23.0" \
    "redis>=3.5.0,<4.0.0" \
    "six==1.13.0" \
    "pyOpenSSL==22.1.0" \
    "cryptography==38.0.1" \
    "google-api-python-client==1.7.8" \
    "google-oauth"

RUN pip install gpustat 
RUN pip install mypy 
RUN pip install deepspeed 
RUN pip install wandb 

RUN pip install torch>=2.1.0


RUN cd /root/ && git clone https://github.com/NVIDIA/cutlass.git
ENV CUTLASS_PATH=/root/cutlass

RUN chmod 1777 /tmp

