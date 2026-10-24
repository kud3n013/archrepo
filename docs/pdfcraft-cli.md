# PdfCraft CLI (`pdfcraft-cli`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.13.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/pdfcraft)

PdfCraft's command-line tool and its opt-in MCP server, for scripts, CI and AI agents. Reads, renders, edits, combines, splits, audits and OCRs PDFs without the desktop app.

---

## 📥 Installation

```bash
sudo pacman -S pdfcraft-cli
```

The desktop app `pdfcraft` depends on this package, so installing the app brings the CLI with it.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `pdfcraft-cli` |
| **Commands** | `pdfcraft-cli` |
| **Current Version** | `0.13.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [storytold/pdfcraft](https://github.com/storytold/pdfcraft) ([MCP guide](https://github.com/storytold/pdfcraft/blob/main/docs/mcp.md)) |
| **License** | MIT OR Apache-2.0 (built-in fonts OFL-1.1) |
| **Category** | CLI Tool |

---

### Overview
Repackages upstream's standalone `pdfcraft-cli-<version>-linux-x86_64.tar.gz` unmodified. It is the same binary the desktop tarball ships in `bin/`.

### MCP server
Installing does not start or register anything; the server only runs when a client launches it. It speaks JSON lines over stdin/stdout, opens no port and stops on EOF.

```bash
# Claude Code
claude mcp add pdfcraft -- pdfcraft-cli mcp --root /work/project
```

```json
{"mcpServers":{"pdfcraft":{"command":"pdfcraft-cli","args":["mcp","--root","/work/project"]}}}
```

- `--root DIR` confines every read and write. `--automation-read-root DIR` and `--automation-write-root DIR` split read and write access, and the other Craft apps take the same flags. `--compact` lists a small core tool set plus `tool_search`/`tool_call`.
- The roots must be existing folders.
- See upstream's [MCP guide](https://github.com/storytold/pdfcraft/blob/main/docs/mcp.md) for the tool list and how the roots are checked.

### Packaging Details
- **Source**: `pdfcraft-cli-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/pdfcraft/releases), checked against upstream's `SHA256SUMS.txt`.
- **Dependencies**: the binary links only glibc and libgcc. Fonts for substitution are built in.
- **OCR**: the text recognition models are not in the CLI tarball. The CLI looks for them in `../share/pdfcraft/models` next to itself, which is `/usr/share/pdfcraft/models` from the `pdfcraft` package (an optional dependency). Without it, `pdfcraft-cli run ocr_status` reports `"available": false`. Set `PDFCRAFT_MODELS` to use another folder.
- **Updates**: the daily check follows the latest GitHub release of `storytold/pdfcraft`, like `pdfcraft`.
- `pdfcraft` up to `0.13.0-1` installed `/usr/bin/pdfcraft-cli` itself. From `0.13.0-2` it depends on this package instead, so a normal `pacman -Syu` moves the file over.

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/pdfcraft)
- [MCP guide](https://github.com/storytold/pdfcraft/blob/main/docs/mcp.md)
- [`pdfcraft` desktop app](pdfcraft.md)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
