# mc-update

mc-update keeps the MinIO client (`mc`) free of known vulnerabilities on networks that
cannot reach the internet. On a connected machine, it raises the vulnerable Go modules of
mc and packs the whole source, dependencies included, into one archive. On the offline
side, the Dockerfile in [`docker/`](docker/Dockerfile) builds `mc` from that archive with
no network access.

MinIO archived the mc repository on 2025-11-20 and no longer publishes binaries or
images. Without this step, an `mc` binary keeps the vulnerabilities of every dependency
it carries.

## TL;DR

Connected side:

```sh
bin/mc-update all -o dist
```

```console
Archive: dist/mc-77f82e18b540-20261125.tar.gz (13M)
SHA-256: cf5fc321220842ab5369ebf81f35e0285b3a57c22551a168dac4b8cb8d21bd7e
Needs Go 1.26.0 or later to build; tested with go1.27.4.
```

Move `dist/mc-77f82e18b540-20261125.tar.gz` and its `.sha256` to the offline side, then
build from the directory that holds them:

```sh
docker build -f docker/Dockerfile \
  --build-arg GO_IMAGE=registry.internal/golang:1.27 \
  --build-arg MC_ARCHIVE=mc-77f82e18b540-20261125.tar.gz \
  --build-arg MC_ARCHIVE_SHA256=cf5fc321220842ab5369ebf81f35e0285b3a57c22551a168dac4b8cb8d21bd7e \
  -t registry.internal/mc:77f82e18b540 .
```

The image holds `/mc` and nothing else. Other images copy it:

```dockerfile
COPY --from=registry.internal/mc:77f82e18b540 /mc /usr/local/bin/mc
```

## Requirements

| Side | Needs |
| --- | --- |
| Connected | `git`, `docker`, `jq`, `tar`, `sha256sum` or `shasum`; access to github.com, proxy.golang.org and vuln.go.dev |
| Offline | Docker with BuildKit, a Go image of the version `pack` names |

Neither side needs Go installed: every Go command runs in a container.

## Documentation

| Page | Read it to |
| --- | --- |
| [How it works](docs/how-it-works.md) | understand the problem, the two sides, and the six Go notions the tool relies on |
| [Commands](docs/commands.md) | use `fetch`, `check`, `bump`, `pack` and `all`, with real output |
| [Offline build](docs/offline-build.md) | build the image without network, check it, and use it in other images |
| [Configuration](docs/configuration.md) | change the Go image, the govulncheck version, the source repository or the cache |
| [Limits and troubleshooting](docs/limits.md) | see what the test build leaves to you, and fix the usual errors |

## License

[MIT](LICENSE)
