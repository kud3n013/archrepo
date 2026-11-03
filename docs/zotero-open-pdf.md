# Open PDF for Zotero (`zotero-open-pdf`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.0.14--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/retorquere/zotero-open-pdf)

Open PDF, EPUB and snapshot attachments in Zotero's internal viewer, the system's default viewer, or custom external viewers.

---

## 📥 Installation

```bash
sudo pacman -S zotero-open-pdf
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zotero-open-pdf` |
| **Current Version** | `1.0.14-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [retorquere/zotero-open-pdf](https://github.com/retorquere/zotero-open-pdf) |
| **Category** | Plugin / Add-on |

---

### Overview
Open PDF adds "Open in …" entries to the right-click menu of attachments, so a PDF, EPUB or web snapshot can be opened in a Zotero tab, a separate Zotero window, the system viewer, or an external program set up in the plugin's preferences.

### Packaging Details
- Packaged as a system-wide extension into `/usr/lib/zotero/distribution/extensions/`.
- Automatically activates for all users running `zotero`.
- Upstream declares no license, so the package uses `LicenseRef-zotero-open-pdf` and installs no license file.

### Known Issues
- In upstream 1.0.14 the PDF, EPUB and Snapshot menus share one menu ID. Zotero rejects the duplicates, so only PDF attachments get the "Open in …" entries.

---


## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/retorquere/zotero-open-pdf)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
