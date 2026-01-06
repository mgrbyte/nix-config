# Standalone Home Manager for Ubuntu/Debian

This configuration can be used on any Linux system (Ubuntu, Debian, etc.) with Nix installed.

## Prerequisites

1. Install Nix (multi-user installation recommended):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enable flakes (add to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`):
   ```
   experimental-features = nix-command flakes
   ```

3. Restart your shell or source the nix profile:
   ```bash
   . /etc/profile.d/nix.sh
   ```

## Usage

From any machine with Nix installed:

```bash
# Clone the repo (first time only)
git clone git@github.com:mgrbyte/nixos-config.git ~/.config/nixos-config
cd ~/.config/nixos-config

# Apply the configuration
nix run home-manager -- switch --flake .#x86_64-linux

# Or for ARM64:
nix run home-manager -- switch --flake .#aarch64-linux
```

## What's included

- **Shell**: zsh with powerlevel10k, completions, aliases
- **Git**: configured with signing, aliases
- **Editors**: vim, emacs config (from github:mgrbyte/emacs.d)
- **Tools**: tmux, fzf, ripgrep, bat, htop, lazygit
- **Languages**: Clojure (deps.edn with aliases)
- **Keyboard**: ctrl:nocaps (Caps Lock → Ctrl) via setxkbmap

## Updating

```bash
cd ~/.config/nixos-config
git pull
nix run home-manager -- switch --flake .#x86_64-linux
```
