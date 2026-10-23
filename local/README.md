# Local-Only Packages 🏠

Recipes in this directory are **built on your own machine, never by CI**.

- CI only builds `packages/*`, so nothing here is compiled, signed or uploaded to the GitHub release.
- They are not in `archrepo.db`: `sudo pacman -S <package>` will not find them.
- They exist because the software cannot legally be redistributed as a binary (for example Microsoft's fonts), but packaging it is still useful.

Build one with `makepkg -si` from its directory, after following the steps at the top of its PKGBUILD.

| Package | Docs | Why it is local only |
|---|---|---|
| [`ttf-ms-win11`](./ttf-ms-win11/) | [docs/ttf-ms-win11.md](../docs/ttf-ms-win11.md) | Microsoft's font EULA forbids redistribution |

Never move a recipe from here into `packages/` without checking its license first: everything in `packages/` is published to a public release.
