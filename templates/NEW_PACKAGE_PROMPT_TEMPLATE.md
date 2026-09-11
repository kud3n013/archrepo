# Comprehensive Package Creation & Maintenance Prompt Template

> **How to use this template:**
> Copy the prompt block below into a new chat with your AI assistant whenever you want to **add**, **copy**, **modify**, or **repackage** a new package for `archrepo`. Fill in the bracketed variables (`[PACKAGE_NAME]`, `[UPSTREAM_URL]`, etc.) before sending.

---

```markdown
You are an expert Arch Linux packaging engineer maintaining the custom pacman repository `kud3n013/archrepo`.

I want to add / modify a package in this repository with the following specifications:
- **Package Name**: [e.g. appname-bin]
- **Existing AUR Package / Link (if known)**: [e.g. https://aur.archlinux.org/packages/appname-bin]
- **Upstream Project / Download URL**: [e.g. https://github.com/org/repo or direct download link]
- **Changelog / Release Page**: [e.g. https://github.com/org/repo/releases]
- **Upstream Distribution Format**: [AppImage / Debian .deb / pre-compiled tarball / raw binary]
- **Package Description**: [Short 1-sentence description]
- **Is it an Electron / Wayland GUI App?**: [Yes / No]
- **Upstream Version Check Strategy**: [github-release / redirect / api-json / manual]

Please follow the mandatory repository architecture, packaging rules, and best practices detailed below.

---

### Step 1: Check the AUR for Existing PKGBUILDs & Community Issues
Before writing a package recipe from scratch, search and inspect the Arch User Repository (AUR):
1. **Fetch the Existing AUR PKGBUILD**:
   - Check if an existing package or related `-bin` package exists on the AUR:
     ```bash
     curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=[pkgname]"
     ```
     *(or clone it to inspect all files: `git clone https://aur.archlinux.org/[pkgname].git /tmp/[pkgname]-aur`)*
   - Use the AUR PKGBUILD as a baseline to copy and modify upon, taking advantage of its tested dependencies, desktop entries, source URLs, and architecture configurations.
2. **Review AUR Comments and Pinned Discussions for Known Pitfalls**:
   - Inspect user comments on the AUR page: `https://aur.archlinux.org/packages/[pkgname]`
   - Look for recently reported issues, recurring user complaints, and proposed workarounds:
     - Blurry scaling, missing flags, or window decoration glitches under Wayland / Hyprland.
     - Rogue autostart files or duplicate `.desktop` shortcuts cluttering application launchers.
     - Missing optional dependencies (`optdepends`) needed for clipboard (e.g. `wl-clipboard`), screen sharing, audio, or camera.
     - Electron version incompatibilities, crash loops, or startup freezes.
     - Post-uninstallation leftovers (unremoved desktop files, cached data).
3. **Proactively Incorporate Community Fixes into Our Build**:
   - Do NOT just blindly copy an AUR PKGBUILD that has known flaws or unaddressed user complaints.
   - Address the issues found in the AUR comments right in our `prepare()`, `.install` scriptlet, or launcher wrapper, ensuring `archrepo` provides a strictly superior, hardened, and hassle-free package.

---

### Step 2: Upstream Pre-Flight & Binary Audit (Don't Waste Build Time & Storage)
1. **Check for existing Arch binary package**:
   - Verify whether upstream's release page already provides an official Arch Linux package (`.pkg.tar.zst` or `.pkg.tar.xz`).
   - If an official `.pkg.tar.zst` exists, do NOT extract and re-package it with `makepkg`; directly adopt or download the official binary into the repository index.
   - If upstream only distributes `.AppImage`, `.deb`, `.rpm`, or `.tar.gz`, confirm that these are upstream binary installers and NOT native Arch packages. These MUST be repackaged into a native `.pkg.tar.zst` using a `-bin` PKGBUILD so `pacman` can track and manage them.
2. **Never compile from source for `-bin` packages**:
   - If the package ends with `-bin`, do NOT invoke `cargo build`, `cmake`, or `make`. Extract the pre-compiled binaries from the upstream archive.

---

### Step 3: Package Directory Structure
Inside the repository root, create `[PACKAGE_NAME]/` with the following standard layout:
```text
[PACKAGE_NAME]/
├── PKGBUILD               # Arch Linux package build recipe
├── .SRCINFO               # Generated package metadata (makepkg --printsrcinfo)
├── [pkgname].install      # Install/upgrade/remove scriptlet (mandatory for desktop apps)
├── [pkgname].sh           # Launcher wrapper script (wayland & flags loader)
├── [pkgname]-flags.conf   # User-configurable flags file (Wayland, DPI scaling, etc.)
├── [pkgname].desktop      # Clean, standard FreeDesktop entry
└── [pkgname].png          # High-resolution application icon (256x256 or 512x512)
```

---

### Step 4: PKGBUILD Rules & Standards
1. **Metadata**:
   - `pkgname=[pkgname]-bin`
   - `_pkgname=[pkgname]`
   - `provides=("${_pkgname}")` and `conflicts=("${_pkgname}")` (along with any obsolete/conflicting variants).
   - `options=(!strip !debug)` for pre-compiled binary packages.
   - `backup=("etc/[pkgname]-flags.conf")` if a system-wide flags file is installed.
   - `install=[pkgname].install` (required if desktop files or user cleanup is involved).
2. **Runtime Dependencies (`depends`)**:
   - Avoid obsolete packages like `fuse2`. If unpacking an AppImage, extract it into `/opt/[pkgname]/` so `fuse2` is never required at runtime.
   - For Electron apps: ensure basic desktop runtime libraries are specified (`gtk3`, `nss`, `alsa-lib`, `libxss`, `libxtst`).
3. **Extraction & Hardening (`prepare()` & `package()`)**:
   - **NTFS / Non-exec mount safety**: When extracting an AppImage in `prepare()`, test execution and fall back to copying to `/tmp` before running `--appimage-extract`.
   - **Remove rogue desktop entries**: Remove any root-level `.desktop` files from `squashfs-root` in `prepare()` to avoid duplicate desktop files.
   - **Permissions**: Ensure executable files have `755` permissions and static assets have `644`. Run `chmod -R u+rwX,go+rX,go-w "${pkgdir}"` at the end of `package()`.

---

### Step 5: Desktop Integration & Clean Uninstallation (`.install` Scriptlet)
To prevent rogue, duplicate, or ghost `.desktop` shortcuts from persisting after uninstallation:
1. **Disable AppImage runtime desktop integration**:
   In the launcher wrapper `[pkgname].sh`, export `DESKTOPINTEGRATION=0`.
2. **Include `[pkgname].install`**:
   Every GUI package must provide an install scriptlet that loops over `/home/*` to purge any user-level copies in `~/.local/share/applications/` and updates the desktop database:
   ```bash
   _cleanup_user_desktops() {
       for user_home in /home/*; do
           if [ -d "$user_home/.local/share/applications" ]; then
               rm -f "$user_home/.local/share/applications/[pkgname].desktop" \
                     "$user_home/.local/share/applications/[PkgName].desktop" 2>/dev/null || true
           fi
       done
       update-desktop-database -q 2>/dev/null || true
   }
   post_install() { _cleanup_user_desktops; }
   post_upgrade() { _cleanup_user_desktops; }
   post_remove()  { _cleanup_user_desktops; }
   ```

---

### Step 6: Wayland, HiDPI Scaling & Launcher Wrapper
For modern Wayland compositors (such as Hyprland, Sway, KDE Wayland) and high-resolution screens:
1. **Launcher Wrapper (`[pkgname].sh`)**:
   - Look for user overrides in `~/.config/[pkgname]-flags.conf`, falling back to `/etc/[pkgname]-flags.conf`.
   - Parse configuration flags line-by-line (ignoring comments and empty lines).
   - If no config file is found and `WAYLAND_DISPLAY` is active, default to:
     `--ozone-platform-hint=auto` and `--enable-wayland-ime`.
   - Execute the target binary: `exec /opt/[pkgname]/[binary] "${FLAGS[@]}" "$@"`.
2. **Flags Configuration (`[pkgname]-flags.conf`)**:
   - Include clear comments documenting:
     - Wayland support (`--ozone-platform-hint=auto`, `--enable-wayland-ime`)
     - High-DPI screen scaling override (`# --force-device-scale-factor=1.5`)
     - Any optional subsystem toggles.
3. **Desktop Entry (`[pkgname].desktop`)**:
   - `Exec=/usr/bin/[pkgname] %U` (pointing to the wrapper script).
   - `StartupWMClass=[correct_wm_class]` (ensures taskbars and docks track the Wayland window properly).
   - `Icon=[pkgname]` (install high-res icon to `/usr/share/icons/hicolor/.../apps/[pkgname].png` and `/usr/share/pixmaps/[pkgname].png`).

---

### Step 7: UI Responsiveness & Non-Blocking Startup Check
- Ensure that the application does NOT perform long-running synchronous calls (e.g. `spawnSync` initializing Wine prefixes, heavy downloads, or blocking IPC) on the Electron main process thread during startup.
- In Wayland, blocking the main thread for > 5 seconds will trigger the compositor's unresponsiveness dialog (`wl_ping` timeout).
- If upstream includes slow initialization, patch it to run asynchronously in the background (`spawn` with Promise or deferred timer).

---

### Step 8: GitHub Actions CI/CD Integration (`.github/workflows/build.yml`)
1. **Add to Build Matrix**:
   Add the new package under `strategy.matrix.package` in `build.yml`:
   ```yaml
   - name: [pkgname]-bin
     upstream_repo: [org/repo or empty]
     upstream_check: [github-release | redirect | custom]
   ```
2. **Configure Version Check**:
   Under step `Check for new upstream release`, add the detection logic for this package's version format.
3. **Cache & Space Hygiene**:
   - Ensure the build job checks if the exact binary (`[pkgname]-[pkgver]-[pkgrel]-x86_64.pkg.tar.zst`) already exists in GitHub Releases (`packages` tag) and skips building if up-to-date.
   - In the `publish` job, ensure package binaries (`*.pkg.tar.zst`) are uploaded ONLY to **GitHub Releases**, and removed before committing to `gh-pages`. The `gh-pages` git tree must strictly host only `archrepo.db*`, `archrepo.files*`, and `index.html`.

---

### Step 9: Verification & Delivery Checklist
Before completing the task:
- [ ] Run `makepkg --printsrcinfo > .SRCINFO` to verify syntax.
- [ ] Test package build with `makepkg` (ensure files, wrapper, flags, and desktop entry are placed in correct `${pkgdir}` paths).
- [ ] Verify tarball contents with `tar -tf [pkgname]-*.pkg.tar.zst`.
- [ ] Clean up local temporary/build files (`src/`, `pkg/`, tarballs).
- [ ] Commit and push changes to `main`.
- [ ] Monitor GitHub Actions workflow run to verify clean build and release publication.
- [ ] Provide user with the exact pacman install command (`sudo pacman -Sy [pkgname]-bin`).
```
