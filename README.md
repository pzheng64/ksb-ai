# ksb-ai

DWPose and Self-Correction Human Parsing (SCHP), plus a shared offline install bundle.

The `offline/` folder is **Linux only**. Wheels are Python 3.12 manylinux builds for x86_64, PyTorch is `2.11.0+cu128` (CUDA 12.8), and `.deb` files are Ubuntu amd64 packages. Install on Ubuntu with Python 3.12 and an NVIDIA driver that supports CUDA 12.8.

## Layout

```
offline/
  common/          shared by DWPose and SCHP
    debs/          Ubuntu packages (Python, build tools, GL, and related libraries)
    wheels/        PyTorch cu128, NVIDIA CUDA wheels, and shared pip packages
  dwpose/          DWPose-only wheels and install-offline.sh
  schp/            SCHP-only wheels and install-offline.sh
DWPose/
Self-Correction-Human-Parsing/
```

`common/` is not installed on its own. Each project installer reads `common/` plus its own subdirectory.

| Directory | What it holds | Install script |
|-----------|----------------|----------------|
| `offline/common` | PyTorch cu128, NVIDIA wheels, Ubuntu `.deb` files, shared packages (numpy, opencv, pillow, …) | used by both scripts below |
| `offline/dwpose` | DWPose / ControlNet wheels (ONNX Runtime, Gradio, and related packages) | `offline/dwpose/install-offline.sh` |
| `offline/schp` | SCHP-only wheels | `offline/schp/install-offline.sh` |

Wheels and `.deb` files are stored with Git LFS. Clone with LFS so those files are the real packages.

```bash
git lfs install
git clone https://github.com/pzheng64/ksb-ai.git
cd ksb-ai
```

If the checkout already exists and the wheel files are only a few lines of pointer text, run `git lfs pull`.

## Install DWPose

From the repo root:

```bash
cd DWPose
bash ../offline/dwpose/install-offline.sh
source .venv/bin/activate
```

The script installs `offline/common/debs` with `dpkg` when passwordless `sudo` is available, creates `DWPose/.venv` with `python3.12`, then installs PyTorch and `offline/dwpose/requirements-dwpose-gpu-py312.txt` from `offline/common/wheels` and `offline/dwpose/wheels` (`pip --no-index`).

## Install SCHP

From the repo root:

```bash
cd Self-Correction-Human-Parsing
bash ../offline/schp/install-offline.sh
source .venv/bin/activate
```

This uses the same `offline/common` wheels and debs, plus `offline/schp/wheels` and `offline/schp/requirements-schp-gpu-py312.txt`.

Pretrained SCHP checkpoints are not in the wheel bundle. On a machine with network:

```bash
bash offline/schp/download-checkpoints.sh
```

## Options

Bundle location, when `offline/` is not next to the project directories:

```bash
export OFFLINE_ROOT=/path/to/offline
```

Skip the Ubuntu package step:

```bash
SKIP_DEBS=1 bash ../offline/dwpose/install-offline.sh
```

When `sudo` needs a password, the installer skips the debs and prints the command. Run it yourself:

```bash
sudo dpkg -i offline/common/debs/*.deb
sudo apt-get install -f
```
