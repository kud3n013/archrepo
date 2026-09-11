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
| [`freedownloadmanager`](./freedownloadmanager/) | [Free Download Manager](https://www.freedownloadmanager.org/) | Archived per maintainer request. |
| [`proton-mail`](./proton-mail/) | [Proton Mail Linux Beta](https://proton.me/mail) | Archived per maintainer request. |
| [`proton-pass`](./proton-pass/) | [Proton Pass Linux](https://proton.me/pass) | Archived per maintainer request. |

---

## How to Reactivate an Archived Package

To reactivate any package from this archive:

1. Move the package directory back to the repository root:
   ```bash
   git mv archive/[package-name] ./
   ```

2. Add the package back to the build matrix in [`.github/workflows/build.yml`](../.github/workflows/build.yml) under `strategy.matrix.package`:
   ```yaml
   - name: [package-name]
     upstream_repo: ""
     upstream_check: [check-type]
   ```

3. Update the package table in [`README.md`](../README.md).

4. Commit and push to `main`. The CI workflow will automatically compile, index, and publish the package back into `archrepo.db`.
