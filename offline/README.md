# Offline bundle

Linux only. These packages are Python 3.12 manylinux wheels for x86_64, PyTorch `2.11.0+cu128` (CUDA 12.8), and Ubuntu amd64 `.deb` files. They install on Ubuntu with Python 3.12 and an NVIDIA driver that supports CUDA 12.8.

See also the repo [README](../README.md).

## Structure

| Directory | Contents | How it is installed |
|-----------|----------|---------------------|
| `common/` | Shared PyTorch cu128 wheels, NVIDIA CUDA wheels, Ubuntu `.deb` packages, and pip packages used by both projects (`wheels/`, `debs/`) | Pulled in by the DWPose and SCHP installers. Nothing in `common/` is installed by itself. |
| `dwpose/` | DWPose / ControlNet wheels and `install-offline.sh` | `bash offline/dwpose/install-offline.sh` from `DWPose/` |
| `schp/` | SCHP-only wheels and `install-offline.sh` | `bash offline/schp/install-offline.sh` from `Self-Correction-Human-Parsing/` |

```
offline/
  common/
    debs/       Ubuntu amd64 packages
    wheels/     torch, torchvision, torchaudio, NVIDIA, and shared wheels
  dwpose/
    wheels/     DWPose-only wheels
    install-offline.sh
  schp/
    wheels/     SCHP-only wheels
    install-offline.sh
```

Fetch the real wheel and `.deb` files with Git LFS (`git lfs pull`) before installing. Pointer files are only a few lines of text.

## Install

From the repo root, with `python3.12` on `PATH`.

DWPose:

```bash
cd DWPose
bash ../offline/dwpose/install-offline.sh
source .venv/bin/activate
```

SCHP:

```bash
cd Self-Correction-Human-Parsing
bash ../offline/schp/install-offline.sh
source .venv/bin/activate
```

Each script installs `common/debs` when passwordless `sudo` works, creates a `.venv` with Python 3.12, and runs `pip install --no-index` using `common/wheels` plus that project's `wheels/` directory.

SCHP checkpoints are separate from this bundle. On a connected machine:

```bash
bash offline/schp/download-checkpoints.sh
```

Move the bundle, or skip the Ubuntu packages:

```bash
export OFFLINE_ROOT=/path/to/offline
SKIP_DEBS=1 bash ../offline/dwpose/install-offline.sh
```

If `sudo` is not passwordless, install the debs first:

```bash
sudo dpkg -i offline/common/debs/*.deb
sudo apt-get install -f
```
