# RunPod.io Deployment Guide

This guide explains how to deploy Boltz on RunPod.io GPU instances using our pre-built Docker image.

## Prerequisites

1. RunPod.io account
2. GitHub Container Registry access
3. Docker image built via GitHub Actions

## Quick Deploy

### Method 1: Using Pre-built Image from GHCR

```bash
# Pull the latest image
docker pull ghcr.io/shadnygren/boltz:latest

# Run on RunPod GPU instance
docker run --gpus all -v /workspace/data:/app/data -v /workspace/results:/app/results \
  ghcr.io/shadnygren/boltz:latest \
  boltz predict /app/data/input.yaml --use_msa_server --out_dir /app/results
```

### Method 2: Using Docker Compose

Create `docker-compose.runpod.yml`:

```yaml
version: '3.8'
services:
  boltz:
    image: ghcr.io/shadnygren/boltz:latest
    container_name: boltz-runpod
    
    # GPU support (automatic on RunPod)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    
    volumes:
      - /workspace/data:/app/data:rw
      - /workspace/results:/app/results:rw
      - /workspace/cache:/root/.boltz:rw
    
    environment:
      - BOLTZ_CACHE=/root/.boltz
      - CUDA_VISIBLE_DEVICES=all
```

## RunPod Template Configuration

### Recommended Instance Type
- **GPU**: RTX 4090, A40, A100 (16GB+ VRAM recommended)
- **CPU**: 8+ cores
- **RAM**: 32GB+ 
- **Storage**: 100GB+ (for models and results)

### Environment Setup Script

```bash
#!/bin/bash
# RunPod startup script

# Update system
apt-get update

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

# Create directories
mkdir -p /workspace/data /workspace/results /workspace/cache

# Pull latest Boltz image
docker pull ghcr.io/shadnygren/boltz:latest

# Set permissions
chmod 777 /workspace/data /workspace/results /workspace/cache

echo "Boltz setup complete! Ready for predictions."
```

## Usage Examples

### Basic Protein Prediction
```bash
# Create input file
cat > /workspace/data/protein.yaml << EOF
sequences:
  - protein:
      id: A
      sequence: MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHFDLSHGSAQVKGHGKKVADALTNAVAHVDDMPNALSALSDLHAHKLRVDPVNFKLLSHCLLVTLAAHLPAEFTPAVHASLDKFLASVSTVLTSKYR
EOF

# Run prediction
docker run --gpus all --rm \
  -v /workspace/data:/app/data \
  -v /workspace/results:/app/results \
  -v /workspace/cache:/root/.boltz \
  ghcr.io/shadnygren/boltz:latest \
  boltz predict /app/data/protein.yaml --use_msa_server --out_dir /app/results
```

### Protein-Ligand with Affinity
```bash
cat > /workspace/data/complex.yaml << EOF
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

docker run --gpus all --rm \
  -v /workspace/data:/app/data \
  -v /workspace/results:/app/results \
  -v /workspace/cache:/root/.boltz \
  ghcr.io/shadnygren/boltz:latest \
  boltz predict /app/data/complex.yaml --use_msa_server --use_potentials --out_dir /app/results
```

## Performance Optimization

### High-Quality Predictions
```bash
# Use more samples and recycling for better accuracy
docker run --gpus all --rm \
  -v /workspace/data:/app/data \
  -v /workspace/results:/app/results \
  -v /workspace/cache:/root/.boltz \
  ghcr.io/shadnygren/boltz:latest \
  boltz predict /app/data/input.yaml \
  --use_msa_server \
  --use_potentials \
  --recycling_steps 10 \
  --diffusion_samples 25 \
  --out_dir /app/results
```

### Fast Screening
```bash
# Minimal settings for rapid screening
docker run --gpus all --rm \
  -v /workspace/data:/app/data \
  -v /workspace/results:/app/results \
  -v /workspace/cache:/root/.boltz \
  ghcr.io/shadnygren/boltz:latest \
  boltz predict /app/data/input.yaml \
  --use_msa_server \
  --diffusion_samples 1 \
  --sampling_steps 50 \
  --out_dir /app/results
```

## Monitoring and Logs

```bash
# Monitor GPU usage
nvidia-smi -l 1

# Follow container logs
docker logs -f boltz-container

# Check disk usage
df -h /workspace
```

## Troubleshooting

### Out of Memory
- Reduce `--diffusion_samples` 
- Lower `--max_msa_seqs 1024`
- Use smaller input sequences

### Slow Performance
- Check GPU utilization with `nvidia-smi`
- Ensure CUDA drivers are up to date
- Verify GPU memory isn't full

### Network Issues
- MSA server requires internet access
- Check firewall settings for outbound HTTPS