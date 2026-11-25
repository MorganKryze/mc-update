# Configuration

mc-update reads five environment variables. None is required.

| Variable | Default | Effect |
| --- | --- | --- |
| `MC_UPDATE_REPOS` | `https://github.com/minio/mc https://github.com/MorganKryze/mc` | repositories `fetch` tries in order, separated by spaces |
| `MC_UPDATE_LOCK` | `sources.lock` next to `bin/` | file of pinned commits and tree hashes |
| `MC_UPDATE_GO_IMAGE` | `golang:1.27` | Go image for every Go command on the connected side, including the test build in `pack` |
| `MC_UPDATE_GOVULNCHECK` | `golang.org/x/vuln/cmd/govulncheck@latest` | govulncheck module and version used by `check` and `bump` |
| `MC_UPDATE_CACHE` | `~/.cache/mc-update` | Go module and build cache kept between runs |

Examples:

```sh
# Test the archive with the Go version of the offline registry.
MC_UPDATE_GO_IMAGE=golang:1.26 mc-update pack -o dist

# Try an internal mirror first, then the public repositories.
MC_UPDATE_REPOS="https://git.internal/mirrors/mc https://github.com/minio/mc https://github.com/MorganKryze/mc" mc-update fetch
```

The repository order matters for speed only: every repository goes through the same
check against `sources.lock`.

## Files written

| Path | Written by | Content |
| --- | --- | --- |
| `DIR/` | `fetch` | mc source; `bump` and `pack` change it in place |
| `OUTDIR/mc-<commit>-<date>.tar.gz` | `pack` | the archive |
| `OUTDIR/mc-<commit>-<date>.tar.gz.sha256` | `pack` | its SHA-256 in `sha256sum` format |
| `MC_UPDATE_CACHE` | every Go command | downloaded modules and build cache; safe to delete |

Go commands run in a container as the calling user, so every file they write belongs to
you.
