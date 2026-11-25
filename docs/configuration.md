# Configuration

mc-update reads four environment variables. None is required.

| Variable | Default | Effect |
| --- | --- | --- |
| `MC_UPDATE_GO_IMAGE` | `golang:1.27` | Go image for every Go command on the connected side, including the test build in `pack` |
| `MC_UPDATE_GOVULNCHECK` | `golang.org/x/vuln/cmd/govulncheck@latest` | govulncheck module and version used by `check` and `bump` |
| `MC_UPDATE_REPO` | `https://github.com/minio/mc` | repository `fetch` downloads from, such as a fork or a mirror |
| `MC_UPDATE_CACHE` | `~/.cache/mc-update` | Go module and build cache kept between runs |

Example: test the archive with the same Go version as the offline registry.

```sh
MC_UPDATE_GO_IMAGE=golang:1.26 mc-update pack -o dist
```

## Files written

| Path | Written by | Content |
| --- | --- | --- |
| `DIR/` | `fetch` | mc source; `bump` and `pack` change it in place |
| `OUTDIR/mc-<commit>-<date>.tar.gz` | `pack` | the archive |
| `OUTDIR/mc-<commit>-<date>.tar.gz.sha256` | `pack` | its SHA-256 in `sha256sum` format |
| `MC_UPDATE_CACHE` | every Go command | downloaded modules and build cache; safe to delete |

Go commands run in a container as the calling user, so every file they write belongs to
you.
