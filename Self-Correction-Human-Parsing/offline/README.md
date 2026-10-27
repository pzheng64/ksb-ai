# Offline install moved

Shared bundle (sibling of this repo):

```
../../offline/
  common/    # PyTorch cu128, debs, shared wheels
  dwpose/    # DWPose / ControlNet offline stack
  schp/      # SCHP scripts + schp-only wheels
```

```bash
bash ../../offline/schp/download-wheels.sh
bash ../../offline/schp/verify-offline-ready.sh
bash ../../offline/schp/install-offline.sh
```

See `../../offline/README.md` and `../../offline/schp/PACK-FOR-OFFLINE.md`.
