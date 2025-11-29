# MobileCLIP2-S0 MLX Safetensors Format

## Overview

Successfully converted MobileCLIP2-S0 weights to MLX safetensors format (.safetensors) from the original NPZ format.

## Generated Files

### Location
`converted_models/mobileclip2-s0/mlx/`

### Files Created

1. **Image Encoder**
   - `image_encoder_weights.safetensors` (43.40 MB)
   - 310 tensors
   - 11,368,534 parameters

2. **Text Encoder**
   - `text_encoder_weights.safetensors` (241.97 MB)
   - 149 tensors
   - 63,428,096 parameters

3. **Configuration Files**
   - `image_encoder_config.json` - Image encoder metadata
   - `text_encoder_config.json` - Text encoder metadata

4. **Utilities**
   - `load_safetensors.py` - Script to load and inspect safetensors weights
   - `load_mlx_model.py` - Original NPZ loader script

## Advantages of Safetensors Format

✅ **Faster Loading**: Safetensors uses memory-mapped files for instant loading  
✅ **Safer**: Built-in validation prevents malicious code execution  
✅ **Standard Format**: Widely adopted in ML community (HuggingFace, MLX)  
✅ **Cross-platform**: Works seamlessly across different frameworks  
✅ **Compact**: Similar or smaller file sizes compared to NPZ  

## Usage

### Loading Image Encoder Weights

```python
from safetensors.numpy import load_file

# Load weights
weights = load_file('image_encoder_weights.safetensors')

# Access individual tensors
stem_weight = weights['trunk.stem.0.reparam_conv.weight']
print(f"Stem weight shape: {stem_weight.shape}")
```

### Loading Text Encoder Weights

```python
from safetensors.numpy import load_file

# Load weights
weights = load_file('text_encoder_weights.safetensors')

# Access individual tensors
embedding = weights['token_embedding.weight']
print(f"Token embedding shape: {embedding.shape}")  # (49408, 512)
```

### Using the Loader Script

```bash
# Load and inspect both encoders
python load_safetensors.py --encoder both --inspect

# Load only image encoder
python load_safetensors.py --encoder image

# Load from specific directory
python load_safetensors.py --model-dir /path/to/mlx --encoder both
```

## Conversion Process

The weights were converted using the custom `convert_npz_to_safetensors.py` script:

```bash
python convert_npz_to_safetensors.py \
    --model-dir ./converted_models/mobileclip2-s0/mlx \
    --encoder both
```

This script:
1. Loads NPZ files containing numpy arrays
2. Converts them to safetensors format
3. Preserves all tensor names and shapes
4. Validates the conversion

## Model Architecture Details

### Image Encoder (11.4M parameters)
- MobileOne-based architecture optimized for mobile devices
- 4 stages with varying channel dimensions (64 → 128 → 256 → 512)
- Efficient depthwise separable convolutions
- Attention blocks in final stage
- Output: 512-dimensional image embeddings

### Text Encoder (63.4M parameters)
- Transformer-based architecture
- 12 transformer blocks
- 512 embedding dimension
- 49,408 token vocabulary
- Context length: 77 tokens
- Output: 512-dimensional text embeddings

## File Size Comparison

| Format | Image Encoder | Text Encoder | Total |
|--------|---------------|--------------|-------|
| NPZ    | 43.46 MB      | 242.00 MB    | 285.46 MB |
| Safetensors | 43.40 MB | 241.97 MB  | 285.37 MB |
| Difference | -0.06 MB | -0.03 MB    | -0.09 MB |

Safetensors achieves slightly smaller file sizes while providing better performance and safety.

## Integration with MLX

To use these weights in an MLX application:

```python
import mlx.core as mx
from safetensors.numpy import load_file

# Load weights
weights = load_file('image_encoder_weights.safetensors')

# Convert numpy arrays to MLX arrays
mlx_weights = {
    name: mx.array(array)
    for name, array in weights.items()
}

# Use in your MLX model
# model.load_weights(mlx_weights)
```

## Next Steps

1. **MLX Model Implementation**: Create native MLX model implementations that can load these weights
2. **Inference Scripts**: Develop inference scripts for image and text encoding
3. **Benchmarking**: Compare performance between NPZ and safetensors loading
4. **Quantization**: Explore quantized versions (INT8, INT4) for even smaller sizes

## References

- [Safetensors Documentation](https://huggingface.co/docs/safetensors)
- [MLX Framework](https://github.com/ml-explore/mlx)
- [MobileCLIP2 Paper](https://arxiv.org/abs/2410.13001)
- [Apple ML Research](https://machinelearning.apple.com/)

---

**Generated**: November 27, 2025  
**Model**: MobileCLIP2-S0  
**Framework**: Apple MLX  
**Format**: Safetensors v0.7.0
