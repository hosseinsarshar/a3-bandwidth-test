import argparse
import logging
import math
import os
import shutil
from contextlib import nullcontext
from pathlib import Path

import accelerate
import datasets
import numpy as np
import PIL
import requests
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.utils.checkpoint
import transformers
from accelerate import Accelerator
from accelerate.logging import get_logger
from accelerate.utils import ProjectConfiguration, set_seed
from datasets import load_dataset
from huggingface_hub import create_repo, upload_folder
from packaging import version
from torchvision import transforms
from tqdm.auto import tqdm
from transformers import CLIPTextModel, CLIPTokenizer

import diffusers
from diffusers import AutoencoderKL, DDPMScheduler, StableDiffusionInstructPix2PixPipeline, UNet2DConditionModel
from diffusers.optimization import get_scheduler
from diffusers.training_utils import EMAModel
from diffusers.utils import check_min_version, deprecate, is_wandb_available
from diffusers.utils.import_utils import is_xformers_available
from diffusers.utils.torch_utils import is_compiled_module



column_names = dataset["train"].column_names
print(f"============== {column_names=} ==============")

DATASET_ID="/gcs/dlexamples-shared-data/diffusers-pix2pix/datasets--timbrooks--instructpix2pix-clip-filtered/preprocessed"
CACHE_DIR="/tmp/sd-pix2pix-cache"
MODEL_NAME="/gcs/dlexamples-shared-data/diffusers-pix2pix/models--runwayml--stable-diffusion-v1-5"
OUTPUT_DIR="/tmp/sd-pix2pix-output"


dataloader_num_workers=20
use_ema=True
enable_xformers_memory_efficient_attention=True
resolution=256 
random_flip=True
train_batch_size=4 
gradient_accumulation_steps=4 
gradient_checkpointing=True
max_train_steps=1000
checkpointing_steps=1000 
checkpoints_total_limit=1
learning_rate=5e-05 
lr_warmup_steps=0
conditioning_dropout_prob=0.05
mixed_precision="fp16"
original_image_column="original_image"
seed=42
dataset_name=DATASET_ID
edit_prompt_column=None
edited_image_column=None
pretrained_model_name_or_path=MODEL_NAME
revision=False
non_ema_revision=False
variant=None
center_crop=False
random_flip=False
DATASET_NAME_MAPPING = {
    "fusing/instructpix2pix-1000-samples": ("input_image", "edit_prompt", "edited_image"),
}
WANDB_TABLE_COL_NAMES = ["original_image", "edited_image", "edit_prompt"]

dataset = load_dataset(
            DATASET_ID,
            None,
            cache_dir=CACHE_DIR,
            streaming=True,
        )


dataset_raw = load_dataset(
            DATASET_ID,
            None,
            cache_dir=CACHE_DIR,
        )


# 6. Get the column names for input/target.
dataset_columns = DATASET_NAME_MAPPING.get(dataset_name, None)
if original_image_column is None:
    original_image_column = dataset_columns[0] if dataset_columns is not None else column_names[0]
else:
    original_image_column = original_image_column
    if original_image_column not in column_names:
        raise ValueError(
            f"--original_image_column' value '{original_image_column}' needs to be one of: {', '.join(column_names)}"
        )
if edit_prompt_column is None:
    edit_prompt_column = dataset_columns[1] if dataset_columns is not None else column_names[1]
else:
    edit_prompt_column = edit_prompt_column
    if edit_prompt_column not in column_names:
        raise ValueError(
            f"--edit_prompt_column' value '{edit_prompt_column}' needs to be one of: {', '.join(column_names)}"
        )
if edited_image_column is None:
    edited_image_column = dataset_columns[2] if dataset_columns is not None else column_names[2]
else:
    edited_image_column = edited_image_column
    if edited_image_column not in column_names:
        raise ValueError(
            f"--edited_image_column' value '{edited_image_column}' needs to be one of: {', '.join(column_names)}"
        )

noise_scheduler = DDPMScheduler.from_pretrained(pretrained_model_name_or_path, subfolder="scheduler")
tokenizer = CLIPTokenizer.from_pretrained(
    pretrained_model_name_or_path, subfolder="tokenizer", revision=revision
)
text_encoder = CLIPTextModel.from_pretrained(
    pretrained_model_name_or_path, subfolder="text_encoder", revision=revision, variant=variant
)
vae = AutoencoderKL.from_pretrained(
    pretrained_model_name_or_path, subfolder="vae", revision=revision, variant=variant
)
unet = UNet2DConditionModel.from_pretrained(
    pretrained_model_name_or_path, subfolder="unet", revision=non_ema_revision
)

# Preprocessing the datasets.
# We need to tokenize input captions and transform the images.
def tokenize_captions(captions):
    inputs = tokenizer(
        captions, max_length=tokenizer.model_max_length, padding="max_length", truncation=True, return_tensors="pt"
    )
    return inputs.input_ids

# Preprocessing the datasets.
train_transforms = transforms.Compose(
    [
        transforms.CenterCrop(resolution) if center_crop else transforms.RandomCrop(resolution),
        transforms.RandomHorizontalFlip() if random_flip else transforms.Lambda(lambda x: x),
    ]
)

def preprocess_images(examples):
    original_images = np.concatenate(
        [convert_to_np(image, resolution) for image in examples[original_image_column]]
    )
    edited_images = np.concatenate(
        [convert_to_np(image, resolution) for image in examples[edited_image_column]]
    )
    # We need to ensure that the original and the edited images undergo the same
    # augmentation transforms.
    images = np.concatenate([original_images, edited_images])
    images = torch.tensor(images)
    images = 2 * (images / 255) - 1
    return train_transforms(images)

def preprocess_train(examples):
    # Preprocess images.
    preprocessed_images = preprocess_images(examples)
    # Since the original and edited images were concatenated before
    # applying the transformations, we need to separate them and reshape
    # them accordingly.
    original_images, edited_images = preprocessed_images.chunk(2)
    original_images = original_images.reshape(-1, 3, resolution, resolution)
    edited_images = edited_images.reshape(-1, 3, resolution, resolution)
    # Collate the preprocessed images into the `examples`.
    examples["original_pixel_values"] = original_images
    examples["edited_pixel_values"] = edited_images
    # Preprocess the captions.
    captions = list(examples[edit_prompt_column])
    examples["input_ids"] = tokenize_captions(captions)
    return examples

train_dataset = dataset_raw["train"].with_transform(preprocess_train)
