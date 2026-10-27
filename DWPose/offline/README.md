# Offline install moved

Python wheels and Ubuntu packages live in the **shared sibling bundle**:

```
../../offline/
  common/    # PyTorch cu128, debs, shared wheels
  dwpose/    # DWPose-only wheels + scripts
  schp/      # SCHP-only wheels + scripts
```

```bash
bash ../../offline/dwpose/download-wheels.sh   # connected machine
bash ../../offline/dwpose/install-offline.sh   # air-gapped target
```

See `../../offline/README.md` and `../../offline/dwpose/README-OFFLINE.md`.
