## hebrew-md-book

[![CI](https://github.com/exital/HeBrewBook/actions/workflows/ci.yml/badge.svg)](https://github.com/exital/HeBrewBook/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/github/actions/workflow/status/exital/HeBrewBook/ci.yml?branch=main&label=tests)](https://github.com/exital/HeBrewBook/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/exital/HeBrewBook?label=release)](https://github.com/exital/HeBrewBook/releases)

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
  ghcr.io/exital/hebrew-md-book:v1.0.0 \
  build
```

This will:

- Discover Markdown files under `/in` (default `*.md`, recursively).
- Generate `book.epub` and `book.pdf` (via an intermediate `book.html`) into `/out`.

Images and other assets in subdirectories of `/in` (e.g. `images/`, `figures/`) are automatically copied into `/out` for the PDF build, so relative paths in your Markdown (e.g. `![](images/cover.png)`) resolve correctly.

See `docs/configuration.md` for full options and `examples/` for sample books.

### Scaffolding example books (`init`)

You can scaffold ready-to-build example books (Hebrew-only, English-only, and mixed HE/EN) into a local directory using the `init` subcommand:

```bash
mkdir -p examples

docker run --rm \
  -v "$PWD/examples:/work" \
  ghcr.io/exital/hebrew-md-book:v1.0.0 \
  init /work
```

This will create:

- `examples/hebrew-only`
- `examples/english-only`
- `examples/mixed-he-en`

You can then point the container at any of these directories as `/in` and run `build`, `epub`, or `pdf` as shown above.
