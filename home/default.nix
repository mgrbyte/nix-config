{ config, pkgs, lib, inputs, emacs-config, emacs-abyss-theme, nix-colors, nix-secrets, user, ... }:

let
  name = "Matt Russell";
  email = "m.russell@bangor.ac.uk";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDir = if isDarwin then "/Users/${user}" else "/home/${user}";

  # PATH components - single source of truth for shell and launchd
  userPaths = [
    "${homeDir}/.local/bin"
    "${homeDir}/.pnpm-packages/bin"
    "${homeDir}/.npm-packages/bin"
    "${homeDir}/bin"
  ];
  systemPaths = [
    "${homeDir}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "/run/wrappers/bin"
    "/run/current-system/sw/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
  nixPath = lib.concatStringsSep ":" (userPaths ++ systemPaths);
in {
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./emacs.nix
    ./terminals.nix
    ./tmux.nix
    ./darwin.nix
    ./age.nix
    ./llms.nix
    ./python-tooling.nix
  ];

  # Make shared variables available to all modules
  _module.args = {
    inherit name user email homeDir nixPath emacs-config emacs-abyss-theme nix-secrets;
  };

  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "26.05";

  colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Ensure XDG_DATA_DIRS includes HM profile paths for GNOME app discovery
  targets.genericLinux.enable = isLinux;

  # Remap Caps Lock to Ctrl in GNOME (Linux only; macOS handled via Karabiner)
  dconf.settings = lib.mkIf isLinux {
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "ctrl:nocaps" ];
    };
  };

  # Custom scripts
  home.file.".local/bin/sync-uv-tools" = {
    source = ../scripts/sync-uv-tools;
    executable = true;
  };

  home.file.".local/bin/claude-ide-external" = {
    source = ../scripts/claude-ide-external;
    executable = true;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };
}
