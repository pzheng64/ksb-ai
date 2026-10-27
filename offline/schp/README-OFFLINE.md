# Offline install (Ubuntu, Python 3.12, CUDA 12.8 GPU)

Offline bundle for **Self-Correction Human Parsing** (SCHP) on a machine without internet.

**Sibling repo:** If [DWPose](../DWPose) already has `offline/wheels` or `offline/debs`, SCHP scripts **reuse those paths** and do not re-download the same files. See [USE-DWPOSE-OFFLINE.md](./USE-DWPOSE-OFFLINE.md).

Before copying to an air-gapped host, run **`bash offline/verify-offline-ready.sh`** (see [PACK-FOR-OFFLINE.md](./PACK-FOR-OFFLINE.md)).

## On a connected machine (linux/x86_64)

Ubuntu system packages only (no pip install, no dpkg install):

```bash
cd /path/to/Self-Correction-Human-Parsing
bash offline/download-debs.sh
```

Full bundle (PyTorch cu128 wheels + Ubuntu debs):

```bash
bash offline/download-wheels.sh
```

Optional archive for transfer:

```bash
tar -czf schp-offline-py312-cu128.tar.gz \
  offline/wheels offline/debs offline/*.sh offline/*.txt offline/README-OFFLINE.md \
  README.md simple_extractor.py networks utils datasets modules
```

Copy the repo (or tarball) to the offline Ubuntu host.

## On the offline machine

1. Install NVIDIA driver + CUDA **12.8+** (from your vendor image).
2. Install system debs if needed (often shared with DWPose):

   ```bash
   sudo dpkg -i ../DWPose/offline/debs/*.deb   # or path in offline/debs/README.txt
   sudo apt-get install -f
   ```

3. Install Python env from wheels only:

   ```bash
   cd /path/to/Self-Correction-Human-Parsing
   bash offline/install-offline.sh
   source .venv/bin/activate
   ```

4. Download pretrained checkpoints separately (Google Drive links in README).

5. Run inference:

   ```bash
   python simple_extractor.py --dataset lip --model-restore [CHECKPOINT] \
     --input-dir [INPUT_PATH] --output-dir [OUTPUT_PATH]
   ```

## Notes

- Wheels target **Python 3.12** on **manylinux** x86_64 (Ubuntu 22.04/24.04).
- Original `environment.yaml` used Python 3.8 + PyTorch 1.5; this offline stack uses **cu128** PyTorch for modern Ubuntu + GPU hosts.
- **mhp_extension** (Detectron2) is not pip-installed here; use the vendored tree under `mhp_extension/detectron2` and build with `pip install -e .` after the offline venv exists.
- `download-debs.sh` resolves recursive apt dependencies into `offline/debs/` without installing them on the download machine.
