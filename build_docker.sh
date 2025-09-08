#!/bin/bash

# Build and test script for Boltz Docker container
set -e

echo "Building Boltz Docker image..."

# Build the image
docker build -t boltz:latest .

echo "Testing Docker image..."

# Test that the image builds successfully and shows help
docker run --rm boltz:latest boltz --help

echo "Testing GPU support (if available)..."
if command -v nvidia-smi &> /dev/null; then
    docker run --gpus all --rm boltz:latest nvidia-smi || echo "GPU test failed - continuing with CPU only"
else
    echo "nvidia-smi not found - skipping GPU test"
fi

echo "Docker image built successfully!"
echo ""
echo "To run predictions:"
echo "1. Create data directory: mkdir -p data results"
echo "2. Place input files in data/"
echo "3. Run: docker-compose run --rm boltz boltz predict /app/data/input.yaml --use_msa_server --out_dir /app/results"