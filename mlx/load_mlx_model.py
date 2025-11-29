"""
MLX Model Loader for MobileCLIP2
Load and use converted MLX weights
"""

import mlx.core as mx
import mlx.nn as nn
import numpy as np
from pathlib import Path
from typing import Dict, Optional


def load_mlx_weights(weights_path: str) -> Dict[str, mx.array]:
    """
    Load MLX weights from NPZ file.
    
    Args:
        weights_path: Path to weights.npz file
    
    Returns:
        Dictionary of weight name to MLX array
    """
    print(f"Loading weights from: {weights_path}")
    
    # Load numpy arrays
    numpy_weights = np.load(weights_path)
    
    # Convert to MLX arrays
    mlx_weights = {}
    for name in numpy_weights.files:
        mlx_weights[name] = mx.array(numpy_weights[name])
    
    print(f"Loaded {len(mlx_weights)} weight tensors")
    return mlx_weights


def load_image_encoder(model_dir: str) -> Dict[str, mx.array]:
    """Load image encoder weights."""
    weights_path = Path(model_dir) / "image_encoder_weights.npz"
    return load_mlx_weights(str(weights_path))


def load_text_encoder(model_dir: str) -> Dict[str, mx.array]:
    """Load text encoder weights."""
    weights_path = Path(model_dir) / "text_encoder_weights.npz"
    return load_mlx_weights(str(weights_path))


def load_full_model(model_dir: str) -> Dict[str, Dict[str, mx.array]]:
    """
    Load both encoders.
    
    Returns:
        Dictionary with 'image' and 'text' encoder weights
    """
    return {
        'image': load_image_encoder(model_dir),
        'text': load_text_encoder(model_dir),
    }


# Example usage
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Load MobileCLIP2 MLX weights")
    parser.add_argument(
        "--model-dir",
        type=str,
        required=True,
        help="Directory containing MLX weights"
    )
    parser.add_argument(
        "--encoder",
        type=str,
        choices=["image", "text", "both"],
        default="both",
        help="Which encoder to load"
    )
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("MobileCLIP2 MLX Model Loader")
    print("=" * 70)
    
    if args.encoder == "both":
        weights = load_full_model(args.model_dir)
        print(f"\nImage encoder: {len(weights['image'])} parameters")
        print(f"Text encoder: {len(weights['text'])} parameters")
    elif args.encoder == "image":
        weights = load_image_encoder(args.model_dir)
        print(f"\nImage encoder: {len(weights)} parameters")
    else:
        weights = load_text_encoder(args.model_dir)
        print(f"\nText encoder: {len(weights)} parameters")
    
    print("\n✓ Weights loaded successfully!")
