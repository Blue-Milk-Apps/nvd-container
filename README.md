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
docker pull ghcr.io/blue-milk-apps/nvd-container:YYYYMMDD
```

## Option B: Build Locally

If you need to control when the NVD data is fetched or want to iterate on the image itself.

### Build (local platform only)

```bash
NVD_API_KEY=<your-key> make build
```

Builds a single-platform image for the current machine. The first build takes 15–30 minutes (NVD database download). Subsequent rebuilds with `--no-cache` pull fresh data.

### Build and push (multi-arch)

To publish a multi-arch image (`linux/amd64` + `linux/arm64`) to a registry:

```bash
NVD_API_KEY=<your-key> REGISTRY=ghcr.io/your-org make push
```

Requires Docker Buildx and an active `docker login` session for the target registry.

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

## Consuming the Data From Another Container

Other containers mount the named volume to access NVD data. No code changes needed in the consumer — just a volume mount. This works the same regardless of whether the image was pulled from GHCR or built locally.

### Option 1: Docker Compose (recommended)

Pull the nvd-container image from GHCR and wire up the shared volume in a single `docker-compose.yml`:

```yaml
services:
  nvd-container:
    image: ghcr.io/blue-milk-apps/nvd-container:latest
    volumes:
      - nvd-owasp-data:/data/owasp

  my-scanner:
    depends_on:
      - nvd-container
    volumes:
      - nvd-owasp-data:/opt/dependency-check/data:ro
    environment:
      - DC_NO_UPDATE=1

volumes:
  nvd-owasp-data:
```

Run `docker compose up` and Compose handles the pull, volume creation, and startup order.

### Option 2: External volume

If you already have the nvd-container running (via `docker run` or another Compose stack), reference its volume as external:

```yaml
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
- **Platforms:** `linux/amd64` and `linux/arm64` (multi-arch manifest)
- **API key:** Read from the `NVD_API_KEY` organization secret

## Project Structure

```
nvd-container/
├── Dockerfile                              # Multi-stage build
├── Makefile                                # build / push / run / stop / status / clean
├── scripts/
│   └── healthcheck.sh                      # Verifies data integrity
└── .github/
    └── workflows/
        └── nightly-nvd-update.yml          # Nightly CI rebuild
```
