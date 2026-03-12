#!/usr/bin/env bash
set -euo pipefail

prog="hebrew-md-book"

log() {
  if [[ "${HEBREW_MD_BOOK_QUIET:-0}" == "1" ]]; then
    return
  fi
  echo "[$prog] $*" >&2
}

verbose() {
  if [[ "${HEBREW_MD_BOOK_VERBOSE:-0}" == "1" ]]; then
    echo "[$prog][verbose] $*" >&2
  fi
}

die() {
  echo "[$prog][error] $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
hebrew-md-book – Hebrew/English Markdown → EPUB/PDF

Usage:
  hebrew-md-book build [options]
  hebrew-md-book epub [options]
  hebrew-md-book pdf [options]
  hebrew-md-book validate [options]
  hebrew-md-book init [target_dir]

Subcommands:
  build     Build both EPUB and PDF (default).
  epub      Build EPUB only.
  pdf       Build PDF only (Markdown → HTML → PDF).
  validate  Validate inputs/metadata/CSS without generating output.
  init      Scaffold an example book structure.

Common options (flags override env, which override files):
  --input-dir DIR        Input directory (default: /in or $INPUT_DIR).
  --output-dir DIR       Output directory (default: /out or $OUTPUT_DIR).
  --md-pattern GLOB      Markdown glob pattern (default: *.md or $MD_PATTERN).
  --metadata FILE        Metadata YAML path (default: metadata.yaml in input dir).
  --epub-css FILE        EPUB CSS path.
  --html-css FILE        HTML/PDF CSS path.
  --lang CODE            Language code (he|en). Default he.
  --dir DIR              Text direction (rtl|ltr). Default rtl.
  --title TITLE          Book title (used if metadata is missing).
  --author AUTHOR        Book author (used if metadata is missing).
  --no-epub              Skip EPUB (build subcommand only).
  --no-pdf               Skip PDF (build subcommand only).
  --dry-run              Show planned actions without writing outputs.
  --quiet                Minimal logging.
  --verbose              Verbose logging.
  -h, --help             Show this help.

Environment variables:
  INPUT_DIR, OUTPUT_DIR, MD_PATTERN, METADATA_FILE,
  EPUB_CSS, HTML_CSS, LANGUAGE, DIRECTION,
  BOOK_TITLE, BOOK_AUTHOR,
  HEBREW_MD_BOOK_QUIET, HEBREW_MD_BOOK_VERBOSE

Precedence:
  flags > env vars > metadata/config files/defaults
EOF
}

resolve_config() {
  INPUT_DIR_RES="${INPUT_DIR:-/in}"
  OUTPUT_DIR_RES="${OUTPUT_DIR:-/out}"
  MD_PATTERN_RES="${MD_PATTERN:-*.md}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input-dir) INPUT_DIR_RES="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR_RES="$2"; shift 2 ;;
      --md-pattern) MD_PATTERN_RES="$2"; shift 2 ;;
      --metadata) METADATA_FILE_RES="$2"; shift 2 ;;
      --epub-css) EPUB_CSS_RES="$2"; shift 2 ;;
      --html-css) HTML_CSS_RES="$2"; shift 2 ;;
      --lang) LANGUAGE_RES="$2"; shift 2 ;;
      --dir) DIRECTION_RES="$2"; shift 2 ;;
      --title) BOOK_TITLE_RES="$2"; shift 2 ;;
      --author) BOOK_AUTHOR_RES="$2"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --no-epub) NO_EPUB=1; shift ;;
      --no-pdf) NO_PDF=1; shift ;;
      --quiet) HEBREW_MD_BOOK_QUIET=1; shift ;;
      --verbose) HEBREW_MD_BOOK_VERBOSE=1; shift ;;
      --) shift; break ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  : "${LANGUAGE_RES:=${LANGUAGE:-${LANGUAGE_RES:-he}}}"
  : "${DIRECTION_RES:=${DIRECTION:-${DIRECTION_RES:-rtl}}}"
  : "${METADATA_FILE_RES:=${METADATA_FILE:-}}"
  : "${EPUB_CSS_RES:=${EPUB_CSS:-}}"
  : "${HTML_CSS_RES:=${HTML_CSS:-}}"
  : "${BOOK_TITLE_RES:=${BOOK_TITLE:-}}"
  : "${BOOK_AUTHOR_RES:=${BOOK_AUTHOR:-}}"

  export INPUT_DIR_RES OUTPUT_DIR_RES MD_PATTERN_RES \
    METADATA_FILE_RES EPUB_CSS_RES HTML_CSS_RES \
    LANGUAGE_RES DIRECTION_RES BOOK_TITLE_RES BOOK_AUTHOR_RES \
    DRY_RUN NO_EPUB NO_PDF HEBREW_MD_BOOK_QUIET HEBREW_MD_BOOK_VERBOSE
}

discover_markdown_files() {
  local dir="$1" pattern="$2"
  mapfile -t MARKDOWN_FILES < <(find "$dir" -type f -name "$pattern" | sort)
  if [[ "${#MARKDOWN_FILES[@]}" -eq 0 ]]; then
    die "No markdown files found under '$dir' matching pattern '$pattern'"
  fi
}

prepare_metadata() {
  local tmp_meta
  if [[ -n "${METADATA_FILE_RES:-}" ]]; then
    if [[ ! -f "$METADATA_FILE_RES" ]]; then
      die "Metadata file not found: $METADATA_FILE_RES"
    fi
    METADATA_ARG=(--metadata-file="$METADATA_FILE_RES")
    return
  fi

  if [[ -f "$INPUT_DIR_RES/metadata.yaml" ]]; then
    METADATA_FILE_RES="$INPUT_DIR_RES/metadata.yaml"
    METADATA_ARG=(--metadata-file="$METADATA_FILE_RES")
    return
  fi

  tmp_meta="$(mktemp)"
  {
    echo "language: ${LANGUAGE_RES:-he}"
    echo "dir: ${DIRECTION_RES:-rtl}"
    if [[ -n "${BOOK_TITLE_RES:-}" ]]; then
      printf 'title: "%s"\n' "$BOOK_TITLE_RES"
    fi
    if [[ -n "${BOOK_AUTHOR_RES:-}" ]]; then
      printf 'author: "%s"\n' "$BOOK_AUTHOR_RES"
    fi
  } >"$tmp_meta"
  METADATA_FILE_RES="$tmp_meta"
  METADATA_ARG=(--metadata-file="$METADATA_FILE_RES")
}

select_css() {
  if [[ -z "${EPUB_CSS_RES:-}" ]]; then
    if [[ -f "$INPUT_DIR_RES/epub.css" ]]; then
      EPUB_CSS_RES="$INPUT_DIR_RES/epub.css"
    else
      EPUB_CSS_RES="/defaults/epub.css"
    fi
  fi
  if [[ -z "${HTML_CSS_RES:-}" ]]; then
    if [[ -f "$INPUT_DIR_RES/html.css" ]]; then
      HTML_CSS_RES="$INPUT_DIR_RES/html.css"
    else
      HTML_CSS_RES="/defaults/html.css"
    fi
  fi
}

cmd_init() {
  local target="${1:-/in}"
  mkdir -p "$target"
  cp -r /examples/hebrew-only "$target/hebrew-only"
  cp -r /examples/english-only "$target/english-only"
  cp -r /examples/mixed-he-en "$target/mixed-he-en"
  log "Scaffolded example books into $target"
}

cmd_validate() {
  shift || true
  resolve_config "$@"

  log "Validating inputs (no outputs will be generated)..."
  discover_markdown_files "$INPUT_DIR_RES" "$MD_PATTERN_RES"
  log "Found ${#MARKDOWN_FILES[@]} markdown files."

  if [[ -n "${METADATA_FILE_RES:-}" && ! -f "$METADATA_FILE_RES" ]]; then
    die "Metadata file not found: $METADATA_FILE_RES"
  fi

  select_css
  if [[ ! -f "$EPUB_CSS_RES" ]]; then
    die "EPUB CSS not found: $EPUB_CSS_RES"
  fi
  if [[ ! -f "$HTML_CSS_RES" ]]; then
    die "HTML/PDF CSS not found: $HTML_CSS_RES"
  fi

  log "Validation passed."
}

run_build() {
  local do_epub="$1" do_pdf="$2"

  log "Using input dir: $INPUT_DIR_RES"
  log "Using output dir: $OUTPUT_DIR_RES"
  log "Markdown pattern: $MD_PATTERN_RES"

  discover_markdown_files "$INPUT_DIR_RES" "$MD_PATTERN_RES"

  log "Discovered ${#MARKDOWN_FILES[@]} markdown files."
  verbose "Files: ${MARKDOWN_FILES[*]}"

  prepare_metadata
  select_css

  log "Language: ${LANGUAGE_RES:-he}, Direction: ${DIRECTION_RES:-rtl}"
  log "Metadata file: $METADATA_FILE_RES"
  log "EPUB CSS: $EPUB_CSS_RES"
  log "HTML/PDF CSS: $HTML_CSS_RES"

  mkdir -p "$OUTPUT_DIR_RES"

  local epub_out="$OUTPUT_DIR_RES/book.epub"
  local html_out="$OUTPUT_DIR_RES/book.html"
  local pdf_out="$OUTPUT_DIR_RES/book.pdf"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[dry-run] Would run Pandoc/WeasyPrint with the above configuration."
    return 0
  fi

  if [[ "$do_epub" == "1" ]]; then
    log "Building EPUB..."
    verbose "Running pandoc for EPUB."
    if ! pandoc "${MARKDOWN_FILES[@]}" \
      "${METADATA_ARG[@]}" \
      --resource-path="$INPUT_DIR_RES" \
      --css="$EPUB_CSS_RES" \
      --toc \
      -o "$epub_out"; then
      die "Pandoc EPUB build failed."
    fi
    log "EPUB written to: $epub_out"
  fi

  if [[ "$do_pdf" == "1" ]]; then
    log "Building HTML for PDF..."
    if ! pandoc "${MARKDOWN_FILES[@]}" \
      "${METADATA_ARG[@]}" \
      --resource-path="$INPUT_DIR_RES" \
      --css="$HTML_CSS_RES" \
      --toc \
      -t html5 -s \
      -o "$html_out"; then
      die "Pandoc HTML build failed."
    fi
    log "HTML written to: $html_out"

    if [[ -d "$INPUT_DIR_RES/images" ]]; then
      log "Copying images directory for PDF assets..."
      cp -r "$INPUT_DIR_RES/images" "$OUTPUT_DIR_RES/images"
    fi

    log "Building PDF via WeasyPrint..."
    if ! weasyprint "$html_out" "$pdf_out"; then
      die "WeasyPrint PDF build failed."
    fi
    log "PDF written to: $pdf_out"
  fi

  log "Done."
}

cmd_build_like() {
  local sub="$1"; shift || true
  local do_epub=1 do_pdf=1
  case "$sub" in
    epub) do_pdf=0 ;;
    pdf) do_epub=0 ;;
  esac

  DRY_RUN=0 NO_EPUB=0 NO_PDF=0
  resolve_config "$@"

  if [[ "${NO_EPUB:-0}" == "1" ]]; then
    do_epub=0
  fi
  if [[ "${NO_PDF:-0}" == "1" ]]; then
    do_pdf=0
  fi

  if [[ "$sub" == "epub" && "$do_epub" -eq 0 ]]; then
    die "--no-epub conflicts with epub subcommand"
  fi
  if [[ "$sub" == "pdf" && "$do_pdf" -eq 0 ]]; then
    die "--no-pdf conflicts with pdf subcommand"
  fi

  run_build "$do_epub" "$do_pdf"
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    build) shift; cmd_build_like build "$@" ;;
    epub) shift; cmd_build_like epub "$@" ;;
    pdf) shift; cmd_build_like pdf "$@" ;;
    validate) cmd_validate "$@" ;;
    init) shift; cmd_init "$@" ;;
    -h|--help|help) usage ;;
    *)
      die "Unknown subcommand: $1"
      ;;
  esac
}

main "$@"

