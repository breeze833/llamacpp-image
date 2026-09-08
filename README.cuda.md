# Containerized llama.cpp Build (CUDA Version)

This project provides a fully featured, lightweight, containerized build of [llama.cpp](https://github.com/ggml-org/llama.cpp). 

> [!NOTE]
> This container image is configured and built for **CUDA execution**. It utilizes NVIDIA CUDA SDK and Runtime.

By default, the container starts a `llama-server` instance configured to download and serve the **Gemma-4-12B** model from Hugging Face. The image contains **all** the compiled `llama.cpp` binary utilities (`llama-cli`, `llama-quantize`, `llama-bench`, etc.) allowing you to override the default program when needed.


---

## 🚀 Quick Start

### 1. Build the Image
To build the container image using **Podman**, run the following command in the project directory:

```bash
podman build -t llamacpp-image -f Dockefile.cuda .
```

### 2. Run the Container (Default)
Run the server with the default configuration (serving Gemma-4-12B on port `8080`):

```bash
podman run -d --name llama-server -p 8080:8080 llamacpp-image
```

Starting on Windows requires some additional options to bind the host resource to the container:

```bash
podman run -d -name llama-server -p 8080:8080 --device /dev/dxg -v /usr/lib/wsl:/usr/lib/wsl:ro -e "LD_LIBRARY_PATH=/usr/lib/wsl/lib" llamacpp-image
```

---

## 💾 Persisting Cached Models

By default, downloaded models will be cached inside the container's ephemeral storage. To reuse downloads and persist models across container restarts, mount a host directory to the `/llama_cache` path inside the container:

```bash
podman run -d --name llama-server \
  --device /dev/dxg -v /usr/lib/wsl:/usr/lib/wsl:ro -e "LD_LIBRARY_PATH=/usr/lib/wsl/lib" \
  -p 8080:8080 \
  -v /path/to/host/model/cache:/llama_cache:Z \
  llamacpp-image
```
*(Note: The `:Z` flag instructs Podman to set the correct SELinux labels on systems where SELinux is active.)*

If you use the Windows Podman, the relative path may not be resolved as what you expect. Use absolute path is stable.

---

For the other descriptions, please refer to [README.md](./README.md).

