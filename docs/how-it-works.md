# How it works

## The problem

`mc` is a Go program. A Go binary carries, compiled in, the code of every module it
depends on and the standard library of the Go version that built it. Image scanners such
as Trivy read that list from the binary and report each module version with a known
advisory.

MinIO archived [github.com/minio/mc](https://github.com/minio/mc) on 2025-11-20 and no
longer publishes binaries or container images. Its dependencies stay at the versions of
the last commit, and each new advisory on one of them becomes a finding in every image
that carries `mc`.

Raising those dependencies needs the internet: Go downloads modules from
proxy.golang.org. A build host on an isolated network cannot do it.

## The two sides

```text
connected machine                                offline network
-----------------                                ---------------
bin/mc-update all
  fetch   mc source at a fixed commit
  bump    raise the vulnerable modules
  pack    copy every dependency into vendor/,
          test build, archive + SHA-256
             |
             |   mc-<commit>-<date>.tar.gz
             |   mc-<commit>-<date>.tar.gz.sha256
             +-------------- transfer -------------> file server
                                                         |
                                                         v
                                                 docker build
                                                   check the SHA-256
                                                   go build, no network
                                                   image holding /mc
```

Everything that needs the internet happens on the connected side. The offline build reads
the archive and a Go image, and nothing else: the Dockerfile sets `GOPROXY=off` and
`GOTOOLCHAIN=local`, and the build passes with `docker build --network=none`.

## Six Go notions

| Notion | Meaning |
| --- | --- |
| module | A Go project and its dependencies. mc is the module `github.com/minio/mc`. |
| `go.mod` | The list of modules mc depends on, each with the minimum version it needs. |
| `go.sum` | The cryptographic hash of every dependency. Go refuses a file that does not match. |
| `go get module@version` | Moves one dependency to a given version and updates `go.mod` and `go.sum`. Other modules move with it when the new version requires it. |
| `go mod tidy` | Brings `go.mod` and `go.sum` in line with the code: adds what is missing, drops what is no longer used. |
| `go mod vendor` | Copies the source of every dependency into `vendor/`. `go build -mod=vendor` then reads that directory and never the network. |

## How `bump` picks versions

`check` runs [govulncheck](https://go.dev/doc/security/vuln/) in module mode. For each
advisory, it reports the module, the version in use and the first version that fixes it.

For each module, `bump` takes the highest of those first fixed versions: the smallest
raise that clears every advisory known on that module. The latest release would bring
changes no advisory asks for.

Modules move one at a time and only upward. Raising `golang.org/x/net` can already pull
`golang.org/x/sys` past its own target; `bump` then leaves `x/sys` where it is instead of
pulling it back down.

Some modules ship fixes on several release lines. Once `bump` raises grpc to v1.83.1,
the next advisory on that line needs v1.83.2. `bump` scans again after each pass and
stops when nothing is left, or when a pass changes nothing.

## Why module mode

govulncheck can also report only the advisories whose code mc calls. mc-update uses
module mode instead, which reports every advisory on a required module. Image scanners
count findings that way, so the result of `check` matches what your scanner will show
on the image.

## What the archive holds

| Path | Content |
| --- | --- |
| `mc-src/` | mc source at the fixed commit, with the raised `go.mod` and `go.sum` |
| `mc-src/vendor/` | source of every dependency |
| `mc-src/.mc-update/commit` | full mc commit hash |
| `mc-src/.mc-update/go.mod.orig` | `go.mod` before any raise |
| `mc-src/.mc-update/changes` | difference between `go.mod.orig` and the final `go.mod` |
| `mc-src/.mc-update/go-min` | oldest Go version able to build the tree |
| `mc-src/.mc-update/go-image`, `go-build` | Go image and version of the test build |
