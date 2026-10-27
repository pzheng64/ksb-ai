# Shared offline bundle (DWPose + SCHP)

Sibling of `DWPose/` and `Self-Correction-Human-Parsing/` under `dev/`.

| Directory | Contents |
|-----------|----------|
| `common/` | PyTorch **cu128**, NVIDIA CUDA wheels, Ubuntu `.deb` packages, shared pip wheels (numpy, opencv, …) |
| `dwpose/` | DWPose / ControlNet-only wheels + `install-offline.sh`, `download-wheels.sh` |
| `schp/` | SCHP-only wheels + `install-offline.sh`, `download-wheels.sh`, checkpoint scripts |

## Download (connected machine)

```bash
# Base + DWPose stack
bash /path/to/dev/offline/dwpose/download-wheels.sh

# SCHP extras (reuses common; no duplicate torch download)
bash /path/to/dev/offline/schp/download-wheels.sh
```

## Install (air-gapped Ubuntu, Python 3.12)

```bash
# DWPose
cd /path/to/dev/DWPose
bash ../offline/dwpose/install-offline.sh

# SCHP
cd /path/to/dev/Self-Correction-Human-Parsing
bash ../offline/schp/install-offline.sh
```

Override bundle location:

```bash
export OFFLINE_ROOT=/path/to/offline
```
