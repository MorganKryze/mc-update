# Offline build

## What to bring

| File | Where it comes from |
| --- | --- |
| `mc-<commit>-<date>.tar.gz` | `mc-update pack` |
| `mc-<commit>-<date>.tar.gz.sha256` | `mc-update pack` |
| `docker/Dockerfile` | this repository |
| a Go image, at least the version `pack` printed | your internal registry |

Store the archive and its `.sha256` on an internal file server, so that every later build
starts from the same file.

## Build

Put the archive in a directory, use that directory as the build context:

```sh
mkdir mc-build && cd mc-build
curl -fO https://files.internal/mc/mc-77f82e18b540-20261125.tar.gz
curl -fO https://files.internal/mc/mc-77f82e18b540-20261125.tar.gz.sha256

docker build -f /path/to/mc-update/docker/Dockerfile \
  --build-arg GO_IMAGE=registry.internal/golang:1.27 \
  --build-arg MC_ARCHIVE=mc-77f82e18b540-20261125.tar.gz \
  --build-arg MC_ARCHIVE_SHA256="$(cut -d' ' -f1 mc-77f82e18b540-20261125.tar.gz.sha256)" \
  -t registry.internal/mc:77f82e18b540 .
```

| Build argument | Required | Meaning |
| --- | --- | --- |
| `GO_IMAGE` | yes | Go image from your registry |
| `MC_ARCHIVE` | yes | archive file name, relative to the build context |
| `MC_ARCHIVE_SHA256` | yes | expected SHA-256 of the archive |

Pass the SHA-256 from a source you trust, such as the value you noted when you made the
archive. The `.sha256` next to the archive catches a damaged transfer. Whoever can replace the
archive can replace that file too.

## What the Dockerfile does

1. Copies the archive from the build context. The build downloads nothing.
2. Checks its SHA-256 with `sha256sum -c` and stops on a mismatch or a missing value.
3. Builds with `GOFLAGS=-mod=vendor`, `GOPROXY=off` and `GOTOOLCHAIN=local`: Go reads only
   `vendor/` and refuses to fetch a module or a toolchain.
4. Runs `mc --version` once to prove the binary starts.
5. Copies `/mc` alone into an empty image, writes the mc commit into the binary and the
   archive SHA-256 into an image label.

The build passes with `docker build --network=none`. Use that flag once to prove a new
archive needs nothing from outside.

## Check the result

```console
$ docker run --rm registry.internal/mc:77f82e18b540 --version
mc version DEVELOPMENT.GOGET (commit-id=77f82e18b5401a65958f1619df6ebb994634bd88)

$ docker image inspect registry.internal/mc:77f82e18b540 \
    --format '{{index .Config.Labels "mc-update.archive.sha256"}}'
cf5fc321220842ab5369ebf81f35e0285b3a57c22551a168dac4b8cb8d21bd7e
```

Scan the image with your scanner. For the archive above, Trivy reports no vulnerability.

Then run mc against a real server before using the new image: see
[Limits](limits.md#untested-behaviour).

## Use mc in other images

```dockerfile
COPY --from=registry.internal/mc:77f82e18b540 /mc /usr/local/bin/mc
```

`mc` is a static binary: it needs no library from the target image.

## Keep it current

Each new advisory on a Go module or on the Go standard library shows up in the scanner
until the cycle runs again:

1. connected side: `mc-update all -o dist`;
2. transfer the archive and its `.sha256`;
3. offline side: build and push a new `mc` image;
4. rebuild the images that copy `/mc`.
