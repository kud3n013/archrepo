# Ladybird Web Browser (`ladybird`)

[![build](https://img.shields.io/badge/build-pending-lightgrey)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-20261103--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#modifications-in-archrepo)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/LadybirdBrowser/ladybird)

A truly independent web browser with its own engine (LibWeb, LibJS), not based on Chromium, WebKit or Gecko. It is pre-alpha software.

---

## 📥 Installation

```bash
sudo pacman -S ladybird
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `ladybird` |
| **Current Version** | `20261103-1` |
| **Package Type** | **Modified** |
| **Build Status** | `pending` |
| **Upstream Project** | [LadybirdBrowser/ladybird](https://github.com/LadybirdBrowser/ladybird), branch `master` |
| **Category** | Core Application (Web Browser) |

---

### Overview
Ladybird publishes no releases, so this package compiles a snapshot of `master` from source. The version is the snapshot commit's date (`YYYYMMDD`). The daily upstream check moves the snapshot to the newest `master` commit only once that commit is at least 7 days newer (`min_age_days` in `upstream.json`), so the package updates about once a week. A full build takes several hours.

### Modifications in `archrepo`
- **Portable CPU baseline:** built with `ENABLE_CI_BASELINE_CPU` (x86-64-v2, SSE4.2/POPCNT) instead of upstream's default `-march=native`, which would tie the binary to the build machine's CPU. The AUR `ladybird` package ships `-march=native`.
- **Upstream's Distribution preset:** static libraries, with Skia, ANGLE, ICU, FFmpeg, curl and the other libraries built by vcpkg at the versions upstream pins in `vcpkg.json`. The vcpkg checkout follows that file's `builtin-baseline`.
- **Pinned Rust toolchain:** the Rust code is built with the toolchain from upstream's `rust-toolchain.toml` (through `rustup`). Arch's newer `rust` fails the build on new deprecation warnings, as reported on the AUR.
- **Always linked with `lld`.** Upstream uses lld only when it finds it installed, and GNU ld fails to link the Rust crates.
- **No `-Werror`** in C++, so a new GCC warning cannot fail a snapshot build.
- vcpkg's static harfbuzz and fontconfig are linked whole into the Qt UI, as in the AUR package.
- `/usr/bin/ladybird` symlink next to upstream's `/usr/bin/Ladybird`.
- Upstream's JavaScript and WebAssembly REPLs are installed as `ladybird-js` and `ladybird-wasm` instead of the generic `js` and `wasm`.

---

## ⚙️ Usage

```bash
ladybird https://example.org

# Render a page without a window
ladybird --headless --screenshot-path page.png https://example.org

# JavaScript REPL on Ladybird's engine (LibJS)
ladybird-js
```

## 🔗 Related Links

- [Upstream Repository](https://github.com/LadybirdBrowser/ladybird)
- [Ladybird Website](https://ladybird.org)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
