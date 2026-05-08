# Emacs Package Management

Emacs packages are managed by Nix, NOT by use-package downloading from MELPA.

## Adding New Emacs Packages

When adding a new Emacs package:

1. **Add to Nix first**: Add the package to `~/github/mgrbyte/nix-config/home/packages.nix` in the `pkgs.emacsPackages` section
2. **Then configure in emacs.d**: Add the `use-package` declaration in `~/github/mgrbyte/emacs.d/lisp/` for configuration only (NOT for installation)

## use-package Declarations

The `use-package` declarations should NOT use `:ensure t` or rely on `use-package-always-ensure` to install packages. Packages are already installed by Nix.

## Why This Matters

- Packages installed from MELPA at runtime are not pinned and can break when versions are removed
- Nix-managed packages are pinned to `flake.lock` and reproducible
- Mixing both approaches causes confusing failures like "package not found" errors
