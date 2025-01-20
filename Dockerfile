# Copyright (c) 2020-2022, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04
FROM $BASE_IMAGE

RUN apt-get update -yq --fix-missing \
 && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    pkg-config \
    wget \
    cmake \
    curl \
    git \
    vim

#ENV PYTHONDONTWRITEBYTECODE=1
#ENV PYTHONUNBUFFERED=1

# nvidia-container-runtime
#ENV NVIDIA_VISIBLE_DEVICES all
#ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,graphics

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    sh Miniconda3-latest-Linux-x86_64.sh -b -u -p ~/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Initialize conda in bash
SHELL ["/bin/bash", "-c"]
ENV PATH="/root/miniconda3/bin:${PATH}"
RUN conda init bash && \
    conda create -n nerfstream python=3.10 -y

# Use conda run for all subsequent commands
RUN conda run -n nerfstream pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/

RUN conda run -n nerfstream conda install pytorch==1.12.1 torchvision==0.13.1 cudatoolkit=11.3 -c pytorch -y
COPY requirements.txt ./
RUN conda run -n nerfstream pip install -r requirements.txt

# additional libraries
RUN conda run -n nerfstream pip install "git+https://github.com/facebookresearch/pytorch3d.git"
RUN conda run -n nerfstream pip install tensorflow-gpu==2.8.0

RUN conda run -n nerfstream pip uninstall protobuf -y
RUN conda run -n nerfstream pip install protobuf==3.20.1

RUN conda run -n nerfstream conda install ffmpeg -y
COPY ../python_rtmpstream /python_rtmpstream
WORKDIR /python_rtmpstream/python
RUN conda run -n nerfstream pip install .

COPY ../nerfstream /nerfstream
WORKDIR /nerfstream
CMD ["conda", "run", "-n", "nerfstream", "python3", "app.py"]