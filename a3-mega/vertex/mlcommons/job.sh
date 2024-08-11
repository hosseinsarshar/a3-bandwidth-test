git clone https://github.com/mlcommons/training.git

cd training/stable_diffusion

scripts/datasets/coco2014-validation-download-prompts.sh --output-dir /workspace/datasets/coco2014
scripts/datasets/coco2014-validation-download-stats.sh --output-dir /workspace/datasets/coco2014

scripts/checkpoints/download_sd.sh --output-dir /workspace/checkpoints/sd
scripts/checkpoints/download_inception.sh --output-dir /workspace/checkpoints/inception
scripts/checkpoints/download_clip.sh --output-dir /workspace/checkpoints/clip

./run_and_time.sh \
  --num-nodes 1 \
  --gpus-per-node 8 \
  --checkpoint /workspace/checkpoints/sd/512-base-ema.ckpt \
  --results-dir /results \
  --config configs/train_01x08x08.yaml