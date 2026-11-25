# Changelog

This file lists the notable changes of each release. It follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-25

### Added

- `mc-update fetch` gets mc at a pinned commit from github.com/minio/mc, falls back to
  the next repository of `MC_UPDATE_REPOS` when one is unreachable, and takes a local
  archive with `-a`.
- `sources.lock` pins each accepted commit to the SHA-256 of its source tree. `fetch`
  refuses and deletes any source that differs, and `pack` refuses a source edited after
  `fetch`.
- `mc-update check` lists the Go modules of mc that carry known advisories.
- `mc-update bump` raises each vulnerable module to the smallest version that fixes it,
  and scans again until nothing is left.
- `mc-update pack` vendors every dependency, test-builds mc and writes the archive with
  its SHA-256.
- `mc-update all` runs `fetch`, `bump` and `pack` in one go.
- `docker/Dockerfile` builds mc from the archive with no network access, after checking
  its SHA-256.

[Unreleased]: https://github.com/MorganKryze/mc-update/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/MorganKryze/mc-update/releases/tag/v0.1.0
