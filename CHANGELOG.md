# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Initial standalone NVD data container with multi-stage Docker build
- OWASP Dependency-Check H2 database built from the official NVD API 2.0
- Makefile with `build`, `run`, `stop`, `status`, and `clean` targets
- GitHub Actions workflow for nightly rebuilds to GHCR
