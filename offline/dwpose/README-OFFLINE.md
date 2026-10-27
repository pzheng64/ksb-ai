# DWPose offline install (Python 3.12, CUDA 12.8)

Bundle root: `../` (`dev/offline/`).

- **common/** — PyTorch `2.11.0+cu128`, NVIDIA wheels, Ubuntu debs, shared deps  
- **dwpose/** — ControlNet / ONNX Runtime / Gradio stack  

## Download (online)

```bash
bash /path/to/dev/offline/dwpose/download-wheels.sh
```

## Install (offline)

```bash
cd /path/to/dev/DWPose
bash ../offline/dwpose/install-offline.sh
source .venv/bin/activate
```

ONNX weights: `ControlNet-v1-1-nightly/annotator/ckpts/` (`dw-ll_ucoco_384.onnx`, `yolox_l.onnx`).
