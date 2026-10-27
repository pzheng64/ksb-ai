# Pack for an air-gapped Ubuntu machine

## Layout

| Path | Role |
|------|------|
| `offline/common/wheels/` | PyTorch cu128 + shared pip wheels |
| `offline/common/debs/` | Ubuntu packages |
| `offline/dwpose/wheels/` | DWPose / ControlNet-only wheels |
| `offline/schp/wheels/` | SCHP-only wheels |
| `Self-Correction-Human-Parsing/checkpoints/` | `exp-schp-*.pth` (~267 MB each) |

## Verify

```bash
bash /path/to/dev/offline/schp/verify-offline-ready.sh
```

## Example tarball

```bash
bash /path/to/dev/offline/dwpose/pack-offline-bundle.sh /path/to/bundle.tar.gz
```

## Install on target

```bash
cd Self-Correction-Human-Parsing
bash ../offline/schp/install-offline.sh
source .venv/bin/activate
```
