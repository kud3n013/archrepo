# Archived Packages 📦🗄️

This directory contains package recipes and maintenance scripts for packages that are **no longer actively distributed** in the `archrepo` pacman repository.

## Why Are Packages Archived?
Packages in this directory:
- Are **excluded** from the automated build and release matrix.
- Are **omitted** from `archrepo.db` — users cannot install them via `sudo pacman -S <package>`.
- Have had their compiled binary assets purged from GitHub Releases.
- Preserve all their PKGBUILDs, launcher scripts, configuration files, and patches in git history for future reference.

---

## Current Archived Packages

| Package | Original Upstream | Reason for Archiving |
|---|---|---|
| [`hyprmod`](./hyprmod/) | [BlueManCZ/hyprmod](https://github.com/BlueManCZ/hyprmod) | Archived per maintainer request. |
| [`zen-browser`](./zen-browser/) | [zen-browser/desktop](https://github.com/zen-browser/desktop) | Archived per maintainer request. |

---

## How to Reactivate an Archived Package

To reactivate any package from this archive:

1. Move the package directory back to `packages/`:
   ```bash
   git mv archive/[package-name] packages/
   ```

2. Update the package table in [`README.md`](../README.md).

3. Commit and push to `main`. The CI workflow will automatically compile, index, and publish the package back into `archrepo.db`.
