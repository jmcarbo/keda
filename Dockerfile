# Build the manager binary
FROM golang:1.16.9 as builder
LABEL org.opencontainers.image.source https://github.com/jmcarbo/keda

ARG BUILD_VERSION=main
ARG TARGETARCH
ARG GIT_COMMIT=HEAD
ARG GIT_VERSION=main

WORKDIR /workspace

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

COPY Makefile Makefile

# Copy the go source
COPY hack/ hack/
COPY version/ version/
COPY main.go main.go
COPY adapter/ adapter/
COPY apis/ apis/
COPY controllers/ controllers/
COPY pkg/ pkg/

# Build
RUN VERSION=${BUILD_VERSION} GIT_COMMIT=${GIT_COMMIT} GIT_VERSION=${GIT_VERSION} ARCH=${TARGETARCH} make manager

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot
LABEL org.opencontainers.image.source https://github.com/jmcarbo/keda
WORKDIR /
COPY --from=builder /workspace/bin/keda .
USER nonroot:nonroot

ENTRYPOINT ["/keda", "--zap-log-level=info", "--zap-encoder=console"]
