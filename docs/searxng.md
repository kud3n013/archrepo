# SearXNG (`searxng`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-r9799.12f8b65--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://searxng.github.io/searxng/)

Privacy-respecting, hackable metasearch engine with systemd service unit and automatic secret key provisioning.

---

## 📥 Installation

```bash
sudo pacman -S searxng
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `searxng` |
| **Current Version** | `r9799.12f8b65-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [searxng/searxng](https://searxng.github.io/searxng/) |
| **Category** | Core Application |

---

### Overview
SearXNG is an open-source metasearch engine that aggregates search results from over 70 search engines while preventing profiling and tracking.

### Modifications in `archrepo`
- Complete Arch Linux system packaging.
- Installs in isolated virtualenv at `/var/lib/searxng/venv`.
- Provides dedicated unprivileged system user `searxng` via `sysusers.d`.
- Provides tmpfiles configuration for runtime directories.
- Automatically generates a cryptographically secure 32-byte secret key upon installation into `/etc/searxng/settings.yml`.
- Includes full systemd service unit `searxng.service` (`systemctl enable --now searxng`).

---

## ⚙️ Configuration & Flags

Configuration file: `/etc/searxng/settings.yml`

```bash
# Start service
sudo systemctl enable --now searxng

# Access web interface at http://127.0.0.1:8888
```

## 🔗 Related Links

- [Upstream Repository / Website](https://searxng.github.io/searxng/)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
