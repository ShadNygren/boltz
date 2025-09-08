# Build arguments for flexible PyTorch base image selection
ARG PYTORCH_VERSION=2.2.0
ARG CUDA_VERSION=12.1
ARG CUDNN_VERSION=8
ARG BASE_IMAGE_VARIANT=runtime

# Use PyTorch with configurable CUDA version as base image
FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${BASE_IMAGE_VARIANT}

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . /app/

# Install Python dependencies
# Install with CUDA support for cuEquivariance acceleration
RUN pip install --no-cache-dir -e .[cuda]

# Create cache directory for Boltz models
RUN mkdir -p /root/.boltz

# Set default environment variables
ENV BOLTZ_CACHE=/root/.boltz
ENV PYTHONPATH=/app:$PYTHONPATH

# Expose any ports if needed (currently none for CLI tool)
# EXPOSE 8000

# Set default command to show help
CMD ["boltz", "--help"]