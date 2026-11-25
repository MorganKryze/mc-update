# Builds mc from an archive made by mc-update. The build needs no network: the archive
# sits in the build context and holds every dependency in its vendor directory.
ARG GO_IMAGE

FROM ${GO_IMAGE} AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG MC_ARCHIVE
ARG MC_ARCHIVE_SHA256
COPY ${MC_ARCHIVE} /tmp/mc.tar.gz
WORKDIR /src
RUN { test -n "$MC_ARCHIVE_SHA256" || { echo "MC_ARCHIVE_SHA256 is required" >&2; exit 1; }; } \
    && echo "$MC_ARCHIVE_SHA256  /tmp/mc.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/mc.tar.gz --strip-components=1 \
    && CGO_ENABLED=0 GOFLAGS=-mod=vendor GOPROXY=off GOTOOLCHAIN=local \
       go build -trimpath \
       -ldflags "-s -w -X github.com/minio/mc/cmd.CommitID=$(cat .mc-update/commit)" \
       -o /mc . \
    && /mc --version

FROM scratch
ARG MC_ARCHIVE_SHA256
LABEL org.opencontainers.image.title="mc" \
      org.opencontainers.image.source="https://github.com/minio/mc" \
      mc-update.archive.sha256="${MC_ARCHIVE_SHA256}"
COPY --from=build /mc /mc
ENTRYPOINT ["/mc"]
