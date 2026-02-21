#!/bin/sh
# Verify NVD data integrity for container healthcheck.

# OWASP Dependency-Check H2 database must exist and be non-empty
[ -f /data/owasp/odc.mv.db ] && [ -s /data/owasp/odc.mv.db ] || exit 1

# At least one JSON feed must exist
ls /data/json/CVE-*.json >/dev/null 2>&1 || exit 1

# Build metadata must exist
[ -f /data/NVD_VERSION.txt ] || exit 1

exit 0
