# Copyright (c) 2020-2022, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04
FROM $BASE_IMAGE

WORKDIR /app

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

# Install and setup conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -u -p /opt/conda

# Add conda to PATH and initialize
ENV PATH=/opt/conda/bin:$PATH
RUN conda init bash && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Create conda environment and install PyTorch
RUN /opt/conda/bin/conda create -n nerfstream python=3.10 -y && \
    /opt/conda/bin/conda install -n nerfstream pytorch==1.12.1 torchvision==0.13.1 cudatoolkit=11.3 -c pytorch -y

# Set pip mirror and install requirements
COPY requirements.txt ./
RUN /opt/conda/bin/conda run -n nerfstream pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    /opt/conda/bin/conda run -n nerfstream pip install --no-cache-dir -r requirements.txt

# Install additional packages
RUN /opt/conda/bin/conda run -n nerfstream pip install --no-cache-dir "git+https://github.com/facebookresearch/pytorch3d.git" && \
    /opt/conda/bin/conda run -n nerfstream pip install --no-cache-dir tensorflow-gpu==2.8.0 && \
    /opt/conda/bin/conda run -n nerfstream pip uninstall -y protobuf && \
    /opt/conda/bin/conda run -n nerfstream pip install --no-cache-dir protobuf==3.20.1 && \
    /opt/conda/bin/conda install -n nerfstream -y ffmpeg

# Copy application code and install
COPY ./python_rtmpstream ./python_rtmpstream
WORKDIR /app/python_rtmpstream/python
RUN /opt/conda/bin/conda run -n nerfstream bash -c "pip install -e . || (cat setup.py && exit 1)"

COPY ./nerfstream ./nerfstream
WORKDIR /app/nerfstream

# Set the default command
CMD ["/opt/conda/bin/conda", "run", "-n", "nerfstream", "python3", "app.py"]