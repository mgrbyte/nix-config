---
paths:
  - "**/*.el"
  - "**/emacs.d/**"
  - "**/emacs/**"
---

# Emacs Configuration Rules

## Source and Deployment

- Emacs config source: `~/github/mgrbyte/emacs.d/`
- Deployed via home-manager (nix store, read-only symlinks)
- To test changes during development:

```bash
hm-emacs-update
```

- Same pattern applies to `~/github/mgrbyte/emacs-abyss-theme/` (published to MELPA)
- Always edit the source repos, never the nix store paths

## Debugging Emacs Issues

When debugging Emacs configuration issues:

1. **Read the source** - Always read the relevant package source code (in `~/.emacs.d/elpa/`) before asking the user to run diagnostic commands
2. **Check defcustom variables** - Many settings are defcustom; understand when `:init` vs `:config` vs `:custom` is appropriate
3. **Understand load order** - use-package keywords run at different times; `:init` before load, `:config` after load

## use-package Conventions

- `:init` - runs before package loads (good for variables that must be set early)
- `:config` - runs after package loads (good for most settings)
- `:custom` - uses customize-set-variable (respects defcustom :set functions)
- `:after` - delays loading until specified packages are loaded
- `:hook` - adds to mode hooks
- `:bind` - sets up keybindings

## Org-mode

- Never add per-file `#+TODO:` directives in org files — they override the global `org-todo-keywords` defined in `init-org.el`, causing the Emacs config to be silently ignored.

## Common Pitfalls

- Setting `lsp-keymap-prefix` must be in `:init` not `:config`
- Lambdas in `:custom` may not work; use `:config` with `setq` instead
- Hidden buffers start with space (` *buffer*`), starred buffers with `*buffer*`
