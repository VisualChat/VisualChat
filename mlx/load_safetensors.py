#!/usr/bin/env python3
"""
Load MobileCLIP2 MLX Safetensors Weights
Example script for loading and inspecting safetensors format weights
"""

from pathlib import Path
from safetensors.numpy import load_file
import numpy as np


def load_image_encoder(model_dir: str = "."):
    """Load image encoder weights from safetensors format."""
    weights_path = Path(model_dir) / "image_encoder_weights.safetensors"
    
    print(f"Loading image encoder from: {weights_path}")
    weights = load_file(str(weights_path))
    
    print(f"✓ Loaded {len(weights)} tensors")
    
    # Calculate total parameters
    total_params = sum(w.size for w in weights.values())
    print(f"  Total parameters: {total_params:,}")
    
    return weights


def load_text_encoder(model_dir: str = "."):
    """Load text encoder weights from safetensors format."""
    weights_path = Path(model_dir) / "text_encoder_weights.safetensors"
    
    print(f"Loading text encoder from: {weights_path}")
    weights = load_file(str(weights_path))
    
    print(f"✓ Loaded {len(weights)} tensors")
    
    # Calculate total parameters
    total_params = sum(w.size for w in weights.values())
    print(f"  Total parameters: {total_params:,}")
    
    return weights


def inspect_weights(weights: dict, show_shapes: bool = True, max_display: int = 10):
    """Display information about loaded weights."""
    print(f"\nWeight tensors ({len(weights)} total):")
    
    for idx, (name, array) in enumerate(weights.items()):
        if idx >= max_display:
            print(f"  ... and {len(weights) - max_display} more tensors")
            break
        
        if show_shapes:
            print(f"  {name:60s} {str(array.shape):20s} {array.dtype}")
        else:
            print(f"  {name}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Load and inspect MobileCLIP2 safetensors weights"
    )
    parser.add_argument(
        "--model-dir",
        type=str,
        default=".",
        help="Directory containing safetensors files"
    )
    parser.add_argument(
        "--encoder",
        type=str,
        choices=["image", "text", "both"],
        default="both",
        help="Which encoder to load"
    )
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="Show detailed weight information"
    )
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("MobileCLIP2 Safetensors Loader")
    print("=" * 70)
    print(f"\nModel directory: {args.model_dir}\n")
    
    # Load encoders
    if args.encoder in ["image", "both"]:
        print("-" * 70)
        image_weights = load_image_encoder(args.model_dir)
        
        if args.inspect:
            inspect_weights(image_weights)
    
    if args.encoder in ["text", "both"]:
        print("-" * 70)
        text_weights = load_text_encoder(args.model_dir)
        
        if args.inspect:
            inspect_weights(text_weights)
    
    print("\n" + "=" * 70)
    print("✓ Weights loaded successfully!")
    print("=" * 70)
    
    print("\nYou can now use these weights in your MLX application.")
    print("The safetensors format is faster and safer than NPZ.")


if __name__ == "__main__":
    main()
