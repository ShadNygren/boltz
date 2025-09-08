# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Boltz is a biomolecular interaction prediction model with two versions:
- **Boltz-1**: First fully open source model approaching AlphaFold3 accuracy
- **Boltz-2**: Latest model that predicts both structures and binding affinities

The codebase is structured as a Python package using PyTorch Lightning for training and inference.

## Development Commands

### Installation and Setup
```bash
# Install from source with CUDA support
pip install -e .[cuda]

# Install without CUDA (CPU-only)
pip install -e .

# Install with development dependencies
pip install -e .[test,lint]
```

### Running Predictions
```bash
# Basic prediction with MSA server
boltz predict input.yaml --use_msa_server

# Prediction with potentials for better physical quality
boltz predict input.yaml --use_msa_server --use_potentials

# Batch prediction from directory
boltz predict input_directory/ --use_msa_server

# Use specific model version
boltz predict input.yaml --model boltz1 --use_msa_server
boltz predict input.yaml --model boltz2 --use_msa_server  # default
```

### Testing
```bash
# Run all tests
pytest

# Run specific test categories
pytest -m "not slow"  # Skip slow tests
pytest -m regression  # Run regression tests only

# Run tests with coverage
pytest --cov=src/boltz tests/
```

### Code Quality
```bash
# Run linting (uses ruff)
ruff check src/

# Auto-fix linting issues
ruff check --fix src/

# Format code
ruff format src/
```

### Training (Boltz-1 only, Boltz-2 coming soon)
```bash
# Debug training (single process, no wandb)
python scripts/train/train.py scripts/train/configs/structure.yaml debug=1

# Full training run
python scripts/train/train.py scripts/train/configs/structure.yaml

# Train confidence model
python scripts/train/train.py scripts/train/configs/confidence.yaml
```

## Architecture Overview

### Core Components
- **`src/boltz/main.py`**: CLI interface and main prediction logic
- **`src/boltz/model/`**: Neural network architectures (Boltz-1 and Boltz-2)
- **`src/boltz/data/`**: Data processing, tokenization, and loading
- **`scripts/`**: Training and evaluation scripts
- **`examples/`**: Sample YAML configuration files

### Model Architecture
- **Pairformer**: Core attention-based architecture for structure prediction
- **MSA Module**: Processes multiple sequence alignments with paired features (Boltz-2)
- **Diffusion Process**: Denoising diffusion for 3D structure generation
- **Affinity Prediction**: Binding affinity estimation (Boltz-2 only)

### Data Flow
1. Input parsing (YAML/FASTA) → tokenization
2. MSA generation (if `--use_msa_server`) via ColabFold API
3. Structure/constraint processing → inference
4. Output writing (CIF/PDB format with confidence scores)

## Key File Locations

### Configuration
- **`pyproject.toml`**: Package configuration, dependencies, ruff settings
- **`scripts/train/configs/`**: Training configurations
- **`examples/`**: Input format examples

### Input Formats
- **YAML format** (preferred): Full feature support including constraints, templates, affinity
- **FASTA format** (deprecated): Limited feature set, polymers only

### Output Structure
```
boltz_results_<input>/
├── predictions/
│   └── <target_id>/
│       ├── <target_id>_model_0.cif  # Best prediction
│       ├── confidence_<target_id>_model_0.json
│       └── affinity_<target_id>.json  # If affinity requested
└── processed/  # Intermediate processed files
```

## Development Notes

### Dependencies
- PyTorch 2.2+, PyTorch Lightning 2.5.0
- RDKit for molecular handling
- Hydra for configuration management
- Optional: cuEquivariance for GPU acceleration
- Redis for multi-process MSA processing

### Testing Strategy
- Unit tests in `tests/` covering model layers and utilities
- Regression tests for model consistency
- Performance profiling tests
- Slow tests marked and excluded by default

### Code Standards
- Uses ruff for linting/formatting (configured in pyproject.toml)
- Numpy-style docstrings
- Type hints required (pyproject.toml enforces this)
- No comments unless explicitly needed (specified in CLAUDE instructions)

### Special Considerations
- Model weights downloaded automatically to `~/.boltz` (configurable via `BOLTZ_CACHE`)
- MSA server authentication via environment variables or CLI flags
- Multi-GPU training supported via PyTorch Lightning DDP
- Supports both structure and affinity prediction in single workflow
## GPG Signing Test
This commit should be verified with GPG signing.
