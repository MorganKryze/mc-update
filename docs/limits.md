# Limits and troubleshooting

## Limits

### Untested behaviour

MinIO no longer tests mc against raised dependencies. The test build in `pack` proves
that mc compiles and starts. Before you use a new image, run a few commands against a
real server, as the user that will run mc:

```sh
mc alias set test https://minio.internal ACCESS_KEY SECRET_KEY
mc mb test/mc-update-check
mc cp ./some-file test/mc-update-check/
mc cat test/mc-update-check/some-file | sha256sum
mc mirror ./some-dir test/mc-update-check/dir
mc rm --recursive --force test/mc-update-check
mc rb test/mc-update-check
mc admin info test
```

### Unreleased fixes

When the only fix for an advisory sits in an unreleased commit, `bump` picks the pseudo-version
the advisory names, such as `v0.58.1-0.20261009181718-2f1f834330b2`. That version names
a commit of the module.

### Archives differ from run to run

tar records file times: two runs of `pack` on the same tree give two different
SHA-256. Trust the `.sha256` written next to each archive, and record it when the archive
leaves the connected side.

### mc reports a development version

`mc --version` shows `DEVELOPMENT.GOGET` and the commit. MinIO's release script reads the
version from git, which the archive does not carry. The commit identifies the source.

## Troubleshooting

| Message | Cause | Fix |
| --- | --- | --- |
| `mc-src already exists` | `fetch` never overwrites | remove the directory, or pass `-d` |
| `no repository in MC_UPDATE_REPOS gave commit …` | every repository was unreachable or lacks the commit | check the network, or `fetch -a` from an archive |
| `commit … is not in sources.lock` | the commit has no pin | see [Pin a new commit](integrity.md#pin-a-new-commit) |
| `the source of … differs from its pin` | someone altered the source, or it arrived incomplete | fetch from another repository or archive; never edit the pin to match |
| `the source tree hashes to …, which no line of sources.lock pins` | an archive whose source matches no pinned commit | use an archive made from a pinned commit |
| `… does not match ….sha256` | the archive differs from the checksum next to it | transfer the archive again |
| `mc-src changed since fetch beyond go.mod and go.sum` | a source file changed between `fetch` and `pack` | fetch again |
| `mc-src holds no source fetched by mc-update` | `check`, `bump` or `pack` on a directory `fetch` did not create | run `fetch` first |
| `jq is required` | `check` and `bump` parse govulncheck's JSON with jq | install jq |
| `/tmp/mc.tar.gz: FAILED` during `docker build` | the archive's SHA-256 differs from `MC_ARCHIVE_SHA256` | transfer the archive again, check the value you passed |
| `MC_ARCHIVE_SHA256 is required` | the build argument is missing | pass it |
| `go.mod requires go >= 1.26.0 (running go 1.25.14; GOTOOLCHAIN=local)` | the Go image is older than the version `pack` printed | use a newer `GO_IMAGE` |
| `base name (${GO_IMAGE}) should not be blank` | `GO_IMAGE` is missing | pass it |
| `Stopped: these modules have no newer fix` | an advisory has no fixed version yet | wait for a fix, or accept the finding |
