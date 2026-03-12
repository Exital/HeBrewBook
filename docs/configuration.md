## Configuration

This tool can be configured via **CLI flags**, **environment variables**, and **files**.  
Precedence is:

**flags > environment variables > metadata/config files/defaults**

### Paths

- **Input directory**
  - Flag: `--input-dir DIR`
  - Env: `INPUT_DIR`
  - Default: `/in`
- **Output directory**
  - Flag: `--output-dir DIR`
  - Env: `OUTPUT_DIR`
  - Default: `/out`
- **Markdown pattern**
  - Flag: `--md-pattern GLOB`
  - Env: `MD_PATTERN`
  - Default: `*.md` (searched recursively under input dir)

### Metadata and CSS

- **Metadata file**
  - Flag: `--metadata FILE`
  - Env: `METADATA_FILE`
  - Files:
    - If not provided, `metadata.yaml` under the input dir is used if present.
    - Otherwise, a minimal metadata file is auto-generated with language/dir/title/author.
- **EPUB CSS**
  - Flag: `--epub-css FILE`
  - Env: `EPUB_CSS`
  - Files:
    - If not provided, `epub.css` under the input dir is used if present.
    - Otherwise, `/defaults/epub.css` is used.
- **HTML/PDF CSS**
  - Flag: `--html-css FILE`
  - Env: `HTML_CSS`
  - Files:
    - If not provided, `html.css` under the input dir is used if present.
    - Otherwise, `/defaults/html.css` is used.

### Language and direction

- **Language**
  - Flag: `--lang CODE`
  - Env: `LANGUAGE`
  - Files: `language` key in metadata.
  - Default: `he`.
- **Direction**
  - Flag: `--dir DIR`
  - Env: `DIRECTION`
  - Files: `dir` key in metadata.
  - Default: `rtl`.

### Book metadata overrides

- **Title**
  - Flag: `--title TITLE`
  - Env: `BOOK_TITLE`
  - Used only when auto-generating metadata.
- **Author**
  - Flag: `--author AUTHOR`
  - Env: `BOOK_AUTHOR`
  - Used only when auto-generating metadata.

### Formats and behavior

- **Formats**
  - `build` subcommand:
    - `--no-epub`: Skip EPUB.
    - `--no-pdf`: Skip PDF.
- **Verbosity**
  - `--quiet` or `HEBREW_MD_BOOK_QUIET=1`: minimal logs.
  - `--verbose` or `HEBREW_MD_BOOK_VERBOSE=1`: detailed logs and commands.
  - Default: normal logs.
- **Dry run**
  - Flag: `--dry-run`
  - Shows resolved configuration, discovered files, and which commands would run, without writing outputs.

### Internal links in Hebrew books

Because section titles in Hebrew use non-ASCII characters, it is safer **not** to rely on Pandoc’s automatic heading IDs for cross‑references.  
For Hebrew books, use explicit anchors or IDs so links work reliably in both HTML and PDF:

- **Recommended pattern (works in HTML and PDF)**:

  In the *target* chapter, add a small anchor before the heading:

  ```markdown
  <a id="ch1"></a>

  # פרק ראשון
  ```

  In another chapter, link to it with:

  ```markdown
  ראו גם את [הפרק הראשון](#ch1).
  ```

  This creates a stable ASCII ID (`ch1`) that Pandoc and WeasyPrint both understand.

- **Alternative using Pandoc heading IDs**:

  ```markdown
  # פרק ראשון {#ch1}
  ```

  and later:

  ```markdown
  ראו גם את [הפרק הראשון](#ch1).
  ```

  This also works, but the explicit `<a id="...">` pattern matches the shipped examples and is easiest to inspect in the generated `book.html`.

See the example Hebrew and mixed-language books under `examples/` for working, copy‑pasteable link patterns.

