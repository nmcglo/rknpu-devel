ARG TARGETPLATFORM=linux/arm64
FROM python:3.12-slim 

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    sudo \
    vim \
    less \
    pkg-config \
    wget \
    curl \
    git \
    zsh \
    cmake \
    ssh \
    openssh-server \
    libopencv-dev \
    python3-dev \
    libgomp1 \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

WORKDIR /opt/rknpu-devel
ENV BUILD_CUDA_EXT=0

# Copy RKNN runtime library in
COPY ./thirdparty/rknn-toolkit2/rknpu2/runtime/Linux/librknn_api/aarch64/librknnrt.so /usr/lib/
RUN chmod 755 /usr/lib/librknnrt.so && ldconfig
COPY ./thirdparty/rknn-toolkit2/rknn-toolkit2/packages/arm64/rknn_toolkit2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl /opt/rknpu-devel/
COPY ./thirdparty/rknn-toolkit2/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl /opt/rknpu-devel/
COPY ./thirdparty/rknn-toolkit2/rknn-toolkit2/packages/arm64/arm64_requirements_cp312.txt /opt/rknpu-devel/

# Copy RKLLM runtime library in
COPY ./thirdparty/rknn-llm/rkllm-runtime/Linux/librkllm_api/aarch64/librkllmrt.so /usr/lib/
RUN chmod 755 /usr/lib/librkllmrt.so && ldconfig

RUN python -m pip install --no-cache-dir -r /opt/rknpu-devel/arm64_requirements_cp312.txt \
    && python -m pip install --no-cache-dir rknn_toolkit2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl \
    && python -m pip install --no-cache-dir rknn_toolkit_lite2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl \
    && rm /opt/rknpu-devel/*

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Create a non-root user (recommended for dev containers)
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY ./config/sshd_config /etc/ssh/sshd_config

USER ${USERNAME}
WORKDIR /workspace

CMD ["/bin/bash"]
