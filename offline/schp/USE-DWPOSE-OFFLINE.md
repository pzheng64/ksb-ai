# Shared offline bundle (replaces `../DWPose/offline`)

Wheels and `.deb` files are **not** duplicated under each repo. Canonical paths:

| Asset | Location |
|-------|----------|
| PyTorch cu128 + shared pip | `offline/common/wheels/` |
| Ubuntu debs | `offline/common/debs/` |
| DWPose-only pip | `offline/dwpose/wheels/` |
| SCHP-only pip | `offline/schp/wheels/` |

Override bundle root:

```bash
export OFFLINE_ROOT=/path/to/offline
```

Download on a connected machine:

```bash
bash offline/dwpose/download-wheels.sh
bash offline/schp/download-wheels.sh
```

Install uses `--find-links` for `common/wheels` + `schp/wheels` (SCHP) or `common` + `dwpose` (DWPose).
