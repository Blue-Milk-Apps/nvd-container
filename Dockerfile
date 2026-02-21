# NVD Data Container
# Multi-stage build: Stage 1 downloads NVD data, Stage 2 serves it via volumes.
# The OWASP DC binary and Java runtime exist only in Stage 1 (discarded).

# =============================================================================
# Stage 1: Download NVD data
# =============================================================================
FROM eclipse-temurin:17-jre-alpine AS downloader

RUN apk add --no-cache bash curl wget unzip xz

# Install OWASP Dependency-Check (used only to run --updateonly)
ARG DEPENDENCY_CHECK_VERSION=12.2.0
RUN wget -q "https://github.com/dependency-check/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip" \
    && unzip -q "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip" -d /opt \
    && rm "dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip"

# Build the H2 database that OWASP Dependency-Check requires
ARG NVD_API_KEY
RUN test -n "$NVD_API_KEY" || { echo "ERROR: NVD_API_KEY build arg is required"; exit 1; } \
    && mkdir -p /data/owasp \
    && /opt/dependency-check/bin/dependency-check.sh \
        --updateonly \
        --data /data/owasp \
        --nvdApiKey "$NVD_API_KEY"

# Download raw NVD JSON feeds (tool-agnostic, for future consumers)
COPY scripts/download-nvd-json.sh /tmp/download-nvd-json.sh
RUN chmod +x /tmp/download-nvd-json.sh && bash /tmp/download-nvd-json.sh /data/json

# Write build metadata
RUN printf "build_date=%s\ndc_version=%s\nsource=NVD API + fkie-cad/nvd-json-data-feeds\n" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "${DEPENDENCY_CHECK_VERSION}" \
    > /data/NVD_VERSION.txt

# =============================================================================
# Stage 2: Minimal data-serving image
# =============================================================================
FROM alpine:3.21

COPY --from=downloader /data /data
COPY scripts/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD /healthcheck.sh

VOLUME ["/data/owasp", "/data/json"]

# Data container pattern: stay alive to serve volumes, zero CPU
CMD ["tail", "-f", "/dev/null"]
