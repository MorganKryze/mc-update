# Commands

Every command runs on the connected machine. `DIR` defaults to `mc-src`, `OUTDIR` to
the current directory.

```text
mc-update fetch [-c COMMIT | -a ARCHIVE] [-d DIR]
mc-update check [-d DIR]
mc-update bump  [-d DIR] [MODULE[@VERSION]...]
mc-update pack  [-d DIR] [-o OUTDIR]
mc-update all   [-c COMMIT | -a ARCHIVE] [-d DIR] [-o OUTDIR]
mc-update help | version
```

## fetch

Puts the mc source into `DIR` and checks it against `sources.lock`. `DIR` must not exist
yet.

From the repositories, with `-c COMMIT` or the default commit (the last line of
`sources.lock`, `77f82e18b540`, the last commit before MinIO archived mc). `fetch` tries
each repository of `MC_UPDATE_REPOS` in order, downloads that commit alone and drops the
git history:

```console
$ mc-update fetch
Fetched mc 77f82e18b540 from https://github.com/minio/mc into mc-src
Source matches sources.lock (tree sha256 19c628dca7728196...)
```

From an archive, with `-a ARCHIVE`: an archive made by `pack`, or the GitHub tarball of a
commit. `fetch` drops `vendor/` and restores the original `go.mod` and `go.sum`, so the
source is the pinned one again:

```console
$ mc-update fetch -a mc-77f82e18b540-20261125.tar.gz
Archive matches mc-77f82e18b540-20261125.tar.gz.sha256
Fetched mc 77f82e18b540 from archive mc-77f82e18b540-20261125.tar.gz into mc-src
Source matches sources.lock (tree sha256 19c628dca7728196...)
```

When the tree matches no pin, `fetch` deletes `DIR` and fails. [Source
integrity](integrity.md) explains the hash and how to pin another commit.

## check

Lists every known advisory on a module mc requires.

```console
$ mc-update check
MODULE                            IN USE    FIXED IN  ADVISORY
github.com/klauspost/compress     v1.18.0   v1.18.7   GO-2026-5841
github.com/prometheus/prometheus  v0.303.0  v0.311.3  GO-2026-5381
golang.org/x/crypto               v0.43.0   v0.45.0   GO-2025-4134
google.golang.org/grpc            v1.74.2   v1.79.3   GO-2026-4762
...
```

After `bump`:

```console
$ mc-update check
No known vulnerability in the modules of mc-src.
```

A `stdlib` line comes from the Go standard library. A newer Go image clears it.

## bump

With no module given, raises each vulnerable module to the smallest version that fixes
all its advisories, then scans again until nothing is left.

```console
$ mc-update bump
Raising modules in mc-src (pass 1):
  github.com/klauspost/compress v1.18.0 -> v1.20.2
  github.com/prometheus/prometheus v0.303.0 -> v0.311.3
  go.etcd.io/etcd/client/pkg/v3 v3.5.19 -> v3.5.33
  golang.org/x/crypto v0.49.0 -> v0.58.1-0.20261009181718-2f1f834330b2
  golang.org/x/net v0.60.0 -> v0.62.0
  golang.org/x/sys v0.49.0 already covers v0.44.0
  golang.org/x/text v0.43.0 already covers v0.41.0
  google.golang.org/grpc v1.79.3 -> v1.83.1
Raising modules in mc-src (pass 2):
  google.golang.org/grpc v1.83.1 -> v1.83.2

Changes to go.mod:
  - go 1.24.0
  + go 1.26.0
  - github.com/klauspost/compress v1.18.0
  + github.com/klauspost/compress v1.20.2
  ...
```

The version in use can be higher than the one `check` showed: an earlier raise in the
same pass already pulled it up.

To raise modules by hand, name them. A module without a version goes to its latest
release:

```sh
mc-update bump golang.org/x/crypto@v0.58.0 google.golang.org/grpc
```

When a pass changes nothing while advisories remain, `bump` stops and names the modules
that have no fix yet.

## pack

Hashes the tree again and stops if a file other than `go.mod` and `go.sum` changed since
`fetch`. Then copies every dependency into `vendor/`, builds mc once to prove the tree
compiles without network, and writes the archive and its checksum.

```console
$ mc-update pack -o dist
Vendoring and test build with golang:1.27...

Archive: dist/mc-77f82e18b540-20261125.tar.gz (13M)
SHA-256: 7232fcf9e7cba5e1a7a252364e13867c38b39aac65a1b90409e0bf09471e528a
Needs Go 1.26.0 or later to build; tested with go1.27.4.

Next: move both files to the offline side and build with docker/Dockerfile.
```

`Needs Go 1.26.0 or later` comes from the `go` line of the final `go.mod`. The Go image
used for the offline build must be at least that version.

## all

Runs `fetch`, `bump` and `pack` in that order and stops at the first failure. It takes
the options of `fetch` and `pack`.

```sh
mc-update all -o dist
mc-update all -a mc-77f82e18b540-20261125.tar.gz -o dist
```
