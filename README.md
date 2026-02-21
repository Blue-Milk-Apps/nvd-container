# NVD Container

Standalone Docker container that downloads and serves the [National Vulnerability Database](https://nvd.nist.gov/) for local consumption. Built to decouple NVD data ownership from any single tool, so multiple containers can share the same database via Docker named volumes.

## What It Provides

| Volume | Path | Contents | Consumer |
|--------|------|----------|----------|
| `nvd-owasp-data` | `/data/owasp` | OWASP Dependency-Check H2 database (`odc.mv.db`) | Tools using OWASP DC (e.g. phoenix-scanner) |

All data is sourced from the official [NVD API 2.0](https://nvd.nist.gov/developers/vulnerabilities) via OWASP Dependency-Check's `--updateonly` mode.

## How It Works

The image uses a multi-stage Docker build:

1. **Stage 1 (discarded)** — An Alpine + JRE image installs OWASP Dependency-Check and runs `--updateonly` to build the H2 database from the official NVD API. The Java runtime, DC binary, and API key exist only in this stage.
2. **Stage 2 (final)** — A minimal Alpine image containing only the data files. Zero runtime processes beyond `tail -f /dev/null` to keep the container alive for volume sharing.

## Prerequisites

- Docker
- An NVD API key (only for local builds) — [request one here](https://nvd.nist.gov/developers/request-an-api-key) (free)

## Option A: Use the Pre-Built Image from GHCR

A nightly CI job publishes a fresh image to GitHub Container Registry. This is the easiest way to get started — no API key or build step required.

```bash
# Pull the latest image
docker pull ghcr.io/blue-milk-apps/nvd-container:latest

# Run it (creates and populates the nvd-owasp-data volume)
docker run -d --name nvd-container \
  -v nvd-owasp-data:/data/owasp \
  ghcr.io/blue-milk-apps/nvd-container:latest
```

A date-tagged image (`:YYYYMMDD`) is also available for pinning or rollback:

```bash
docker pull ghcr.io/blue-milk-apps/nvd-container:20260221
```

## Option B: Build Locally

If you need to control when the NVD data is fetched or want to iterate on the image itself.

### Build

```bash
NVD_API=<your-key> make build
```

The first build takes 15–30 minutes (NVD database download). Subsequent rebuilds with `--no-cache` pull fresh data.

### Run

```bash
make run
```

Starts the container and populates the `nvd-owasp-data` named volume.

## Managing the Container

### Check Status

```bash
make status
```

Shows container health and prints the `NVD_VERSION.txt` metadata (build date, DC version, data source).

### Stop & Clean

```bash
make stop    # stop and remove container
make clean   # stop container and remove named volumes
```

## Consuming the Data

Other containers mount the named volume to access NVD data. No code changes needed in the consumer — just a volume mount. This works the same regardless of whether the image was pulled from GHCR or built locally.

Mount `nvd-owasp-data` at the path Dependency-Check expects and set offline mode:

```yaml
# In the consumer's docker-compose.yml
volumes:
  nvd-owasp-data:
    external: true

services:
  my-scanner:
    volumes:
      - nvd-owasp-data:/opt/dependency-check/data:ro
    environment:
      - DC_NO_UPDATE=1
```

## CI/CD

A GitHub Actions workflow (`.github/workflows/nightly-nvd-update.yml`) rebuilds the image on a nightly schedule:

- **Trigger:** Daily at 2 AM UTC + manual dispatch
- **Registry:** GitHub Container Registry (`ghcr.io`)
- **Tags:** `:latest` and `:YYYYMMDD` (for rollback)
- **API key:** Read from the `NVD_API` organization secret

## Project Structure

```
nvd-container/
├── Dockerfile                              # Multi-stage build
├── Makefile                                # build / run / stop / status / clean
├── scripts/
│   └── healthcheck.sh                      # Verifies data integrity
└── .github/
    └── workflows/
        └── nightly-nvd-update.yml          # Nightly CI rebuild
```
