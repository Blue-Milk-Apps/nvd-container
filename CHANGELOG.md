# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Initial standalone NVD data container with multi-stage Docker build
- OWASP Dependency-Check H2 database built from the official NVD API 2.0
- Makefile with `build`, `push`, `run`, `stop`, `status`, and `clean` targets
- GitHub Actions workflow for nightly rebuilds to GHCR
- Multi-arch manifest support for `linux/amd64` and `linux/arm64` via Docker Buildx
- Makefile `push` target for manually publishing a multi-arch image to a registry
