#!/usr/bin/env python3
"""Classify wheels into common / dwpose / schp by top-level requirement names."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = Path(__file__).resolve().parent  # set via argv
COMMON = ROOT / "common" / "wheels"
DWPOSE = ROOT / "dwpose" / "wheels"
SCHP = ROOT / "schp" / "wheels"

TORCH_FAMILY = {
    "torch", "torchvision", "torchaudio", "triton",
    "nvidia", "cuda", "cuda_toolkit", "cuda_bindings", "cuda_pathfinder",
}

SCHP_TOP = {
    "numpy", "opencv_python", "pillow", "tqdm", "cython", "pycocotools", "fvcore",
    "iopath", "cloudpickle", "omegaconf", "hydra_core", "tabulate", "termcolor", "yacs",
    "antlr4_python3_runtime",
}

DWPOSE_TOP = {
    "onnxruntime_gpu", "matplotlib", "scipy", "einops", "gradio", "gradio_client",
    "albumentations", "albucore", "imageio", "imageio_ffmpeg", "pytorch_lightning",
    "lightning_utilities", "transformers", "tokenizers", "webdataset", "kornia",
    "kornia_rs", "open_clip_torch", "invisible_watermark", "torchmetrics", "timm",
    "addict", "yapf", "prettytable", "safetensors", "streamlit",
}
# Shared with SCHP (also in DWPose requirements)
SHARED_TOP = {
    "numpy", "opencv_python", "pillow", "tqdm", "pycocotools", "fvcore", "omegaconf",
    "tabulate", "termcolor", "iopath",
}

SCHP_ONLY_TOP = SCHP_TOP - SHARED_TOP - TORCH_FAMILY
DWPOSE_ONLY_TOP = DWPOSE_TOP - SHARED_TOP - TORCH_FAMILY


def norm_dist(name: str) -> str:
    return name.lower().replace("-", "_")


def dist_from_wheel(filename: str) -> str:
    name = filename
    if name.endswith(".tar.gz"):
        base = name[:-7]
    elif name.endswith(".whl"):
        base = name[:-4]
    else:
        return norm_dist(name)
    # PEP 440 wheel: {dist}-{ver}(-{build})?-{py}-{abi}-{plat}
    m = re.match(r"^(.+?)-(\d|\+)", base)
    if not m:
        return norm_dist(base.split("-")[0])
    return norm_dist(m.group(1))


def bucket(dist: str) -> str:
    if dist in TORCH_FAMILY or dist.startswith("nvidia_"):
        return "common"
    if dist in SHARED_TOP:
        return "common"
    if dist in SCHP_ONLY_TOP:
        return "schp"
    if dist in DWPOSE_ONLY_TOP:
        return "dwpose"
    # Transitive deps: prefer common so SCHP stays small
    return "common"


def main(src: Path) -> None:
    for d in (COMMON, DWPOSE, SCHP):
        d.mkdir(parents=True, exist_ok=True)
    counts = {"common": 0, "dwpose": 0, "schp": 0}
    for path in sorted(src.iterdir()):
        if not path.is_file():
            continue
        if not (path.name.endswith(".whl") or path.name.endswith(".tar.gz")):
            continue
        dist = dist_from_wheel(path.name)
        b = bucket(dist)
        dest_dir = {"common": COMMON, "dwpose": DWPOSE, "schp": SCHP}[b]
        dest = dest_dir / path.name
        if dest.exists():
            continue
        shutil.move(str(path), str(dest))
        counts[b] += 1
    print("Moved wheels:", counts)


if __name__ == "__main__":
    import sys
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/home/server/dev/DWPose/offline/wheels")
    main(src)
