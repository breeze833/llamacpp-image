# Stage 1: Build stage
FROM debian:trixie-slim AS build

# Install build-time dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cmake \
    git \
    libopenblas-dev \
    pkg-config \
    libcurl4-openssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /llama_build
RUN git clone https://github.com/ggml-org/llama.cpp.git

WORKDIR /llama_build/llama.cpp
# Configure CMake. Explicitly enable BLAS and CURL for HuggingFace downloading.
RUN cmake -B build \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=OpenBLAS \
    -DLLAMA_CURL=ON

# Build all targets (cli, server, quantize, bench, etc.) to allow full functionality
RUN cmake --build build --config Release

# Install all built targets and assets to a clean folder /install
RUN cmake --install build --prefix /install

# Stage 2: Minimal runtime stage
FROM debian:trixie-slim

# Install runtime dependencies (OpenBLAS, curl, and CA certs for downloading models)
RUN apt-get update && apt-get -y install --no-install-recommends \
    libopenblas0 \
    libopenblas0-openmp \
    libcurl4t64 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy ALL built binaries, libraries, and headers from the build stage
COPY --from=build /install /usr/local

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Post-copy setup: Update linker cache, create cache folder, and make entrypoint executable
RUN ldconfig && \
    mkdir -p /llama_cache && \
    chmod 777 /llama_cache && \
    chmod +x /usr/local/bin/entrypoint.sh

# Set default configuration variables (overridable)
ENV LLAMA_CACHE=/llama_cache
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD [ "-hf", "ggml-org/gemma-4-E2B-it-GGUF" ]
