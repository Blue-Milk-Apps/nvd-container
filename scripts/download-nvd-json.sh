#!/usr/bin/env bash
set -euo pipefail

# Downloads NVD JSON feeds from fkie-cad/nvd-json-data-feeds GitHub releases.
# These are tool-agnostic CVE data files for consumers that don't use OWASP DC.
# Usage: download-nvd-json.sh /output/dir

OUTPUT_DIR="${1:?Usage: download-nvd-json.sh /output/dir}"
mkdir -p "$OUTPUT_DIR"

BASE_URL="https://github.com/fkie-cad/nvd-json-data-feeds/releases/latest/download"
CURRENT_YEAR=$(date +%Y)

for year in $(seq 2002 "$CURRENT_YEAR"); do
    echo "Downloading CVE-${year}.json.xz ..."
    curl -sSfL "${BASE_URL}/CVE-${year}.json.xz" -o "${OUTPUT_DIR}/CVE-${year}.json.xz"
    xz -d -k "${OUTPUT_DIR}/CVE-${year}.json.xz"
done

for feed in CVE-Recent CVE-Modified; do
    echo "Downloading ${feed}.json.xz ..."
    curl -sSfL "${BASE_URL}/${feed}.json.xz" -o "${OUTPUT_DIR}/${feed}.json.xz"
    xz -d -k "${OUTPUT_DIR}/${feed}.json.xz"
done

echo "downloaded=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${OUTPUT_DIR}/FEED_VERSION.txt"
echo "source=fkie-cad/nvd-json-data-feeds" >> "${OUTPUT_DIR}/FEED_VERSION.txt"
echo "years=2002-${CURRENT_YEAR}" >> "${OUTPUT_DIR}/FEED_VERSION.txt"

echo "NVD JSON feeds downloaded to ${OUTPUT_DIR}"
