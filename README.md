# image-syncer

A simple tool to sync images from a source to a destination.

# Usage
```bash
make help

Usage:
  make <target>

General
  help             Display this help.

Sync
  update-ca        Fetch new CA from server.
  sync             Sync multi-architecture image to local registry, usage: make sync <DOMAIN=core.harbor.domain> <IMG=golang:1.21.7-bullseye> .

Environment
  install-ca       install ca chart.
  install-harbor   install harbor.
```

## Installation

```bash
# generate ca
make install-ca

# install harbor using generated ca
make install-harbor
```

## Fetch new CA from server

```bash
make update-ca
```

## Sync multi-architecture image to local registry

```bash
make sync <DOMAIN=core.harbor.domain> <IMG=golang:1.21.7-bullseye>

# examples

# sync docker.io/golang:1.22.4 to core.harbor.domain/library/golang:1.22.4
make sync IMG=golang:1.22.4

# sync with specified DOMAIN [ docker.io/golang:1.22.4 -> dockerhub.internal.domain/library/golang:1.22.4 ]
make sync DOMAIN=dockerhub.internal.domain IMG=golang:1.22.4

# sync with specified PROXY
make sync PROXY=127.0.0.1:7890 IMG=golang:1.22.4

# sync with specified PROXY & PLATFORMS
make sync PROXY=127.0.0.1:7890 PLATFORMS=linux/arm64,linux/amd64 IMG=golang:1.22.4
```
