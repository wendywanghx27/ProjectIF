# SAM3 Hourly Plant Segmentation Pipeline

## What it does
- Watches an input folder for new or modified images.
- Runs SAM3 text-prompt segmentation with prompt `"plant"` (configurable).
- Writes masked images where plant pixels keep original color and all other pixels are black.
- Runs a second script to count non-black pixels and logs the count.

## Files
- `multiSegment.py`: watcher + segmentation pipeline
- `pixel_count.py`: standalone masked-image pixel counter
- `Dockerfile`: container image
- `docker-compose.yml`: single-service deployment
- `.env.example`: environment template

## Run with Docker Compose
1. Copy `.env.example` to `.env` and set host paths.
2. From this directory:
   ```bash
   docker compose up --build
   ```

Pipeline logs include lines like:
```text
pixel_count: image=/data/output/example_1234abcd_plant_mask.png plant_pixels=12345
```

## Local run (optional)
Set env vars (`INPUT_DIR`, `MASK_OUTPUT_DIR`, `STATE_FILE`) and run:
```bash
python multiSegment.py
```
