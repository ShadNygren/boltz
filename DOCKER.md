# Docker Setup for Boltz

This Docker setup provides a containerized environment for running Boltz biomolecular predictions with CUDA support.

## Prerequisites

- Docker Engine 20.10.0+
- Docker Compose v2.0.0+
- NVIDIA Docker runtime (for GPU support)
- NVIDIA GPU with CUDA 12.1+ compatible drivers

### Installing NVIDIA Docker Support

```bash
# Add NVIDIA Docker repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

## Flexible Dockerfile with Build Args

The Dockerfile supports multiple PyTorch and CUDA versions through build arguments:

### Build Arguments
- **`PYTORCH_VERSION`** (default: `2.2.0`) - PyTorch version
- **`CUDA_VERSION`** (default: `12.1`) - CUDA version  
- **`CUDNN_VERSION`** (default: `8`) - cuDNN version
- **`BASE_IMAGE_VARIANT`** (default: `runtime`) - Use `runtime` or `devel`

### Current Build Matrix

Our GitHub Actions automatically builds multiple variants:

| Variant | Base Image | Image Tag Suffix |
|---------|------------|------------------|
| **Stable CUDA 12.1** | `pytorch/pytorch:2.2.0-cuda12.1-cudnn8-runtime` | `-cuda12.1` |
| **Stable CUDA 11.8** | `pytorch/pytorch:2.2.0-cuda11.8-cudnn8-runtime` | `-cuda11.8` |  
| **Latest CUDA 12.9** | `pytorch/pytorch:2.8.0-cuda12.9-cudnn9-runtime` | `-cuda12.9` |

### Generated Image Tags

Images are automatically published to GitHub Container Registry:

```bash
# Stable variants (tested)
ghcr.io/shadnygren/boltz:latest-cuda12.1
ghcr.io/shadnygren/boltz:latest-cuda11.8

# Latest variant (experimental)  
ghcr.io/shadnygren/boltz:latest-cuda12.9

# Branch-specific tags
ghcr.io/shadnygren/boltz:docker-pytorch-<sha>-cuda12.1
ghcr.io/shadnygren/boltz:docker-pytorch-<sha>-cuda11.8
ghcr.io/shadnygren/boltz:docker-pytorch-<sha>-cuda12.9
```

## Quick Start

### 1. Build Custom Docker Image

```bash
# Build with default settings (CUDA 12.1)
docker build -t boltz:latest .

# Build with custom PyTorch/CUDA version
docker build --build-arg PYTORCH_VERSION=2.8.0 \
             --build-arg CUDA_VERSION=12.9 \
             --build-arg CUDNN_VERSION=9 \
             -t boltz:cuda12.9 .

# Build development variant with extra tools
docker build --build-arg BASE_IMAGE_VARIANT=devel \
             -t boltz:devel .

# Or using docker-compose
docker-compose build
```

### 2. Use Pre-built Images

```bash
# Pull stable CUDA 12.1 image
docker pull ghcr.io/shadnygren/boltz:latest-cuda12.1

# Pull experimental CUDA 12.9 image  
docker pull ghcr.io/shadnygren/boltz:latest-cuda12.9

# Pull CUDA 11.8 for older hardware
docker pull ghcr.io/shadnygren/boltz:latest-cuda11.8
```

### 3. Prepare Input Data

```bash
# Create directories
mkdir -p data results

# Place your YAML input files in the data directory
cp your_input.yaml data/
```

### 4. Run Predictions

#### Using Docker Compose (Recommended)
```bash
# Run a prediction
docker-compose run --rm boltz boltz predict /app/data/your_input.yaml \
    --use_msa_server \
    --out_dir /app/results

# Interactive mode for debugging
docker-compose run --rm boltz /bin/bash
```

#### Using Docker Directly
```bash
# Run with GPU support
docker run --gpus all -v $(pwd)/data:/app/data -v $(pwd)/results:/app/results \
    boltz:latest boltz predict /app/data/your_input.yaml \
    --use_msa_server --out_dir /app/results

# Interactive debugging
docker run --gpus all -it -v $(pwd)/data:/app/data -v $(pwd)/results:/app/results \
    boltz:latest /bin/bash
```

## Directory Structure

```
boltz/
├── Dockerfile              # Docker build configuration
├── docker-compose.yml      # Docker Compose setup with GPU support
├── .dockerignore           # Files to exclude from Docker build
├── data/                   # Input directory (mounted as volume)
│   └── input.yaml         # Your input files
├── results/               # Output directory (mounted as volume)
│   └── boltz_results_*/   # Prediction results
└── DOCKER.md             # This documentation
```

## Configuration

### Environment Variables

- `BOLTZ_CACHE=/root/.boltz` - Model cache directory
- `CUDA_VISIBLE_DEVICES=all` - GPU device selection

### Volume Mounts

- `./data:/app/data` - Input data directory
- `./results:/app/results` - Output results directory  
- `boltz_cache:/root/.boltz` - Persistent model cache

### GPU Memory Requirements

- **Minimum**: 8GB VRAM for small molecules
- **Recommended**: 16GB+ VRAM for larger complexes
- **CPU-only**: Remove `--gpus all` flag (much slower)

## Example Usage

### Basic Protein-Ligand Prediction

```bash
# Create input file
cat > data/protein_ligand.yaml << EOF
sequences:
  - protein:
      id: A
      sequence: MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHFDLSHGSAQVKGHGKKVADALTNAVAHVDDMPNALSALSDLHAHKLRVDPVNFKLLSHCLLVTLAAHLPAEFTPAVHASLDKFLASVSTVLTSKYR
  - ligand:
      id: B
      smiles: 'CC(C)CC1=CC=C(C=C1)C(C)C(=O)O'
properties:
  - affinity:
      binder: B
EOF

# Run prediction
docker-compose run --rm boltz boltz predict /app/data/protein_ligand.yaml \
    --use_msa_server \
    --out_dir /app/results
```

### Advanced Options

```bash
# Use potentials for better physical quality
docker-compose run --rm boltz boltz predict /app/data/input.yaml \
    --use_msa_server \
    --use_potentials \
    --diffusion_samples 5 \
    --out_dir /app/results

# CPU-only execution (much slower)
docker run -v $(pwd)/data:/app/data -v $(pwd)/results:/app/results \
    boltz:latest boltz predict /app/data/input.yaml \
    --use_msa_server \
    --accelerator cpu \
    --out_dir /app/results
```

## Troubleshooting

### GPU Not Detected
```bash
# Test GPU access in container
docker run --gpus all --rm boltz:latest nvidia-smi
```

### Memory Issues
```bash
# Reduce memory usage
docker-compose run --rm boltz boltz predict /app/data/input.yaml \
    --use_msa_server \
    --diffusion_samples 1 \
    --max_msa_seqs 1024 \
    --out_dir /app/results
```

### Build Issues
```bash
# Clean build
docker system prune -f
docker-compose build --no-cache
```

## Performance Notes

- Model weights (~2GB) are downloaded on first run
- MSA generation requires internet connectivity
- GPU acceleration provides 10-100x speedup over CPU
- Results are persistent in the `results/` directory
- Model cache is persistent via Docker volume