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

# Install and setup conda in a single RUN command
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -u -p ~/miniconda3 && \
    ~/miniconda3/bin/conda init bash && \
    . ~/miniconda3/etc/profile.d/conda.sh && \
    conda create -n nerfstream python=3.10 -y && \
    conda activate nerfstream && \
    pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    conda install pytorch==1.12.1 torchvision==0.13.1 cudatoolkit=11.3 -c pytorch -y

COPY requirements.txt ./
RUN . ~/miniconda3/etc/profile.d/conda.sh && \
    conda activate nerfstream && \
    pip install -r requirements.txt && \
    pip install "git+https://github.com/facebookresearch/pytorch3d.git" && \
    pip install tensorflow-gpu==2.8.0 && \
    pip uninstall protobuf -y && \
    pip install protobuf==3.20.1 && \
    conda install ffmpeg -y

COPY python_rtmpstream /python_rtmpstream
WORKDIR /python_rtmpstream/python
RUN . ~/miniconda3/etc/profile.d/conda.sh && \
    conda activate nerfstream && \
    pip install .

COPY nerfstream /nerfstream
WORKDIR /nerfstream

# Make sure the container starts with conda environment activated
SHELL ["conda", "run", "-n", "nerfstream", "/bin/bash", "-c"]
CMD ["python3", "app.py"]