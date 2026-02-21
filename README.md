# NVD Container

Standalone Docker container that downloads and serves the [National Vulnerability Database](https://nvd.nist.gov/) for local consumption. Built to decouple NVD data ownership from any single tool, so multiple containers can share the same database via Docker named volumes.

## What It Provides

| Volume | Path | Contents | Consumer |
|--------|------|----------|----------|
| `nvd-owasp-data` | `/data/owasp` | OWASP Dependency-Check H2 database (`odc.mv.db`) | Tools using OWASP DC (e.g. phoenix-scanner) |
| `nvd-json-data` | `/data/json` | Yearly CVE JSON feeds (2002–present) | Any tool that reads raw NVD JSON |

## How It Works

The image uses a multi-stage Docker build:

1. **Stage 1 (discarded)** — An Alpine + JRE image installs OWASP Dependency-Check, runs `--updateonly` to build the H2 database, and downloads raw JSON feeds from [fkie-cad/nvd-json-data-feeds](https://github.com/fkie-cad/nvd-json-data-feeds). The Java runtime, DC binary, and API key exist only in this stage.
2. **Stage 2 (final)** — A minimal Alpine image containing only the data files. Zero runtime processes beyond `tail -f /dev/null` to keep the container alive for volume sharing.

## Prerequisites

- Docker
- An NVD API key — [request one here](https://nvd.nist.gov/developers/request-an-api-key) (free)

## Usage

### Build

```bash
NVD_API_KEY=<your-key> make build
```

The first build takes 15–30 minutes (NVD database download). Subsequent rebuilds with `--no-cache` pull fresh data.

### Run

```bash
make run
```

Starts the container and populates the `nvd-owasp-data` and `nvd-json-data` named volumes.

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

Other containers mount the named volumes to access NVD data. No code changes needed in the consumer — just a volume mount.

### OWASP Dependency-Check consumers

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

### Raw JSON consumers

Mount `nvd-json-data` for direct access to yearly CVE feeds:

```yaml
volumes:
  nvd-json-data:
    external: true

services:
  my-tool:
    volumes:
      - nvd-json-data:/nvd:ro
```

Files available: `CVE-2002.json` through `CVE-<current-year>.json`, plus `CVE-Recent.json` and `CVE-Modified.json`. Compressed `.json.xz` originals are also retained.

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
│   ├── download-nvd-json.sh                # Fetches yearly JSON feeds
│   └── healthcheck.sh                      # Verifies data integrity
└── .github/
    └── workflows/
        └── nightly-nvd-update.yml          # Nightly CI rebuild
```
