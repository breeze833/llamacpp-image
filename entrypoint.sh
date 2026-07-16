#!/bin/bash
# Ensure the model cache directory exists
mkdir -p /llama_cache

# Run llama-server and let it replace bash as PID 1
exec llama-server "$@"
