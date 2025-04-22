# Stage 1: Build stage to copy required scripts
FROM ubuntu:24.04 as build
COPY ./start-llama-cpp.sh ./start-ollama.sh ./benchmark_llama-cpp.sh /llm/scripts/

# Stage 2: Final image
FROM intel/oneapi-basekit:2025.1.0-0-devel-ubuntu24.04

# Build args
ARG http_proxy
ARG https_proxy
ARG TZ=Asia/Shanghai
ARG DEBIAN_FRONTEND=noninteractive

# Set environment
ENV TZ=$TZ \
    PYTHONUNBUFFERED=1 \
    SYCL_CACHE_PERSISTENT=1

# Copy scripts from build stage
COPY --from=build /llm/scripts /llm/scripts/

# Install packages and configure system
RUN set -eux && \
    chmod +x /llm/scripts/*.sh && \
    \
    # Intel OneAPI & GPU repo setup
    wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/intel-oneapi-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/intel-oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/oneAPI.list && \
    #wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg && \
    #echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble unified" | tee /etc/apt/sources.list.d/intel-gpu-noble.list&& \
    chmod 644 /usr/share/keyrings/*.gpg && \
    \
    # Base packages and Python 3.11 (no pip from apt!)
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget git sudo tzdata gnupg \
        libunwind8-dev software-properties-common \
        python3.11 python3.11-dev python3.11-distutils python3-wheel && \
    \
    #rm /etc/apt/sources.list.d/intel-graphics.list && \
    # Set timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    \
    # Make Python 3.11 default
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && ln -sf /usr/bin/python3 /usr/bin/python && \
    \
    # Install pip manually to avoid uninstall issues
    wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && python3 get-pip.py && rm get-pip.py && \
    \
    # Python packages
    pip install --upgrade pip && \
    pip install --upgrade requests argparse urllib3 && \
    pip install --pre --upgrade ipex-llm[cpp] && \
    pip install transformers==4.36.2 transformers_stream_generator einops tiktoken && \
    \
    # Remove conflicting Intel GPU libs
    apt-get remove -y libze-dev libze-intel-gpu1 && \
    \
    # Install Intel Compute Runtime (25.13)
    mkdir -p /tmp/gpu && cd /tmp/gpu && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.10.8/intel-igc-core-2_2.10.8+18926_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.10.8/intel-igc-opencl-2_2.10.8+18926_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.13.33276.16/intel-level-zero-gpu_1.6.33276.16_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.13.33276.16/intel-opencl-icd_25.13.33276.16_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/25.13.33276.16/libigdgmm12_22.7.0_amd64.deb && \
    dpkg -r intel-ocloc-dev intel-ocloc libze-intel-gpu1 || true && \
    dpkg -i *.deb && rm -rf /tmp/gpu && \
    \
    # Install oneAPI Level Zero Loader
    mkdir -p /tmp/level-zero && cd /tmp/level-zero && \
    wget https://github.com/oneapi-src/level-zero/releases/download/v1.21.9/level-zero_1.21.9+u22.04_amd64.deb && \
    wget https://github.com/oneapi-src/level-zero/releases/download/v1.21.9/level-zero-devel_1.21.9+u22.04_amd64.deb && \
    dpkg -i *.deb && rm -rf /tmp/level-zero && \
    \
    # Cleanup to reduce image size
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache /usr/share/doc /usr/share/man && \
    find /usr/lib/python3/dist-packages/ -name 'blinker*' -exec rm -rf {} +

# Set work directory
WORKDIR /llm/
