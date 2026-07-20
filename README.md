# Containerized llama.cpp Build

This project provides a fully featured, lightweight, containerized build of [llama.cpp](https://github.com/ggml-org/llama.cpp). 

> [!NOTE]
> This container image is configured and built for **CPU execution**. It utilizes native CPU optimization. Therefore, it should be built on the target platform for determining the proper CPU features. It does not include GPU acceleration (CUDA, ROCm, etc.).

By default, the container starts a `llama-server` instance configured to download and serve the **Gemma-4-E2B** model from Hugging Face. The image contains **all** the compiled `llama.cpp` binary utilities (`llama-cli`, `llama-quantize`, `llama-bench`, etc.) allowing you to override the default program when needed.


---

## 🚀 Quick Start

### 1. Build the Image
To build the container image using **Podman**, run the following command in the project directory:

```bash
podman build -t llamacpp-image .
```

### 2. Run the Container (Default)
Run the server with the default configuration (serving Gemma-4-E2B on port `8080`):

```bash
podman run -d --name llama-server -p 8080:8080 llamacpp-image
```

---

## 💾 Persisting Cached Models

By default, downloaded models will be cached inside the container's ephemeral storage. To reuse downloads and persist models across container restarts, mount a host directory to the `/llama_cache` path inside the container:

```bash
podman run -d --name llama-server \
  -p 8080:8080 \
  -v /path/to/host/model/cache:/llama_cache:Z \
  llamacpp-image
```
*(Note: The `:Z` flag instructs Podman to set the correct SELinux labels on systems where SELinux is active.)*

---

## ⚙️ Configuration & Customization

### Passing Command-Line Arguments
Any arguments passed to the container will be forwarded directly to the `llama-server` process.

* **Serve a different Hugging Face model:**
  ```bash
  podman run -d -p 8080:8080 -v /my/cache:/llama_cache:Z llamacpp-image -hf ggml-org/gemma-2-2b-it-GGUF
  ```
* **Adjust inference settings (e.g., context size and temperature):**
  > [!IMPORTANT]
  > Because trailing command-line arguments override the default container `CMD` entirely, you **must** specify the model source (e.g., using `-hf` or `-m`) whenever you pass custom options.

  ```bash
  # Example downloading a Hugging Face model:
  podman run -d -p 8080:8080 -v /my/cache:/llama_cache:Z llamacpp-image -hf ggml-org/gemma-4-E2B-it-GGUF -c 4096 --temp 0.2

  # Example using a manually downloaded local model file inside the cache:
  podman run -d -p 8080:8080 -v /my/cache:/llama_cache:Z llamacpp-image -m /llama_cache/my_model.gguf -c 4096 --temp 0.2
  ```


### Environment Variables
You can configure `llama.cpp` using environment variables. Any environment variable prefixed with `LLAMA_ARG_` translates directly into an argument for the server.

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `LLAMA_CACHE` | `/llama_cache` | The directory where downloaded GGUF models are stored. |
| `LLAMA_ARG_HOST` | `0.0.0.0` | IP address the server binds to (`0.0.0.0` is required for external access). |
| `LLAMA_ARG_PORT` | `8080` | The port the HTTP API server listens on. |

To override these variables at runtime:
```bash
podman run -d -p 9000:9000 \
  -e LLAMA_ARG_PORT=9000 \
  -v /my/cache:/llama_cache:Z \
  llamacpp-image
```

---

## 🛠️ Experimenting with Other Utilities

This image packages the entire compiled suite of `llama.cpp` programs. You can run utilities other than `llama-server` by overriding the container entrypoint using `--entrypoint`.

### Run CLI Inference (`llama-cli`)
Use `llama-cli` to interact with a model directly from your terminal:

```bash
podman run -it --rm \
  --entrypoint llama-cli \
  -v /path/to/host/model/cache:/llama_cache:Z \
  llamacpp-image \
  -hf ggml-org/gemma-2-2b-it-GGUF -p "Explain quantum computing in one sentence."
```

### Quantize a Model (`llama-quantize`)
Perform model quantization on a locally stored GGUF file:

```bash
podman run -it --rm \
  --entrypoint llama-quantize \
  -v /path/to/host/model/cache:/llama_cache:Z \
  llamacpp-image \
  /llama_cache/model-f32.gguf /llama_cache/model-q4_k_m.gguf q4_k_m
```

### Benchmark Performance (`llama-bench`)
Run performance benchmarks for your hardware configuration:

```bash
podman run -it --rm \
  --entrypoint llama-bench \
  -v /path/to/host/model/cache:/llama_cache:Z \
  llamacpp-image \
  -m /llama_cache/ggml-org/gemma-4-E2B-it-GGUF/gemma-4-e2b-it-q8_0.gguf
```
