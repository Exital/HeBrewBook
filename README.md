## hebrew-md-book

[![CI](https://github.com/<user>/HeBrewBook/actions/workflows/ci.yml/badge.svg)](https://github.com/<user>/HeBrewBook/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/<user>/HeBrewBook?label=release)](https://github.com/<user>/HeBrewBook/releases)

Small, version‑pinned Docker image that converts **Hebrew and English Markdown** into **EPUB** and **PDF**, with correct RTL support and sensible defaults for automation pipelines.

### Features

- **Markdown → EPUB** using Pandoc.
- **Markdown → HTML → PDF** using WeasyPrint.
- **Hebrew‑first defaults**: RTL layout, Noto Sans Hebrew fonts.
- **Subcommands**: `build`, `epub`, `pdf`.
- **Configurable via flags and env vars**, with clear precedence:
  - Flags **>** environment variables **>** metadata/config files.

### Basic usage

Assuming you have a directory `book/` containing your Markdown files and (optionally) `metadata.yaml` and CSS:

```bash
docker run --rm \
  -v "$PWD/book:/in" \
  -v "$PWD/out:/out" \
  ghcr.io/<user>/hebrew-md-book:v1.0.0 \
  build
```

This will:

- Discover Markdown files under `/in` (default `*.md`, recursively).
- Generate `book.epub` and `book.pdf` (via an intermediate `book.html`) into `/out`.

See `docs/configuration.md` for full options and `examples/` for sample books.

