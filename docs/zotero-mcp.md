# Zotero MCP Server & CLI (`zotero-mcp`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.13.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/54yyyu/zotero-mcp)

Model Context Protocol (MCP) server and standalone CLI connecting AI assistants and LLMs directly to your local Zotero library.

---

## 📥 Installation

```bash
sudo pacman -S zotero-mcp
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zotero-mcp` |
| **Current Version** | `0.13.1-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [54yyyu/zotero-mcp](https://github.com/54yyyu/zotero-mcp) |
| **Category** | Plugin / Add-on |

---

### Overview
`zotero-mcp` allows AI agents (like Claude Desktop, Google Antigravity, or custom LLM tooling) to query, search, cite, and read notes from your local Zotero database via standard MCP protocol.

### Packaging Details
- Installed into an isolated Python virtual environment at `/opt/zotero-mcp/venv` using `uv`.
- Provides executable wrapper scripts: `/usr/bin/zotero-mcp`, `/usr/bin/zotero-cli`, and `/usr/bin/zotero-mcp-server`.

---


## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/54yyyu/zotero-mcp)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
