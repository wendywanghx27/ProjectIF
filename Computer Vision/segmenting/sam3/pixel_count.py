#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def count_non_black_pixels(image_path: Path) -> int:
    with Image.open(image_path) as img:
        arr = np.array(img.convert("RGB"))
    return int(np.any(arr > 0, axis=-1).sum())


def main() -> int:
    parser = argparse.ArgumentParser(description="Count plant pixels in a masked image.")
    parser.add_argument("--image", required=True, help="Path to a masked RGB image.")
    args = parser.parse_args()

    image_path = Path(args.image)
    if not image_path.exists():
        print(f"image not found: {image_path}", file=sys.stderr)
        return 1

    try:
        pixels = count_non_black_pixels(image_path)
    except Exception as exc:
        print(f"failed to count pixels image={image_path} error={exc}", file=sys.stderr)
        return 1

    print(f"image={image_path} plant_pixels={pixels}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
