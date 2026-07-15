{ config, pkgs, lib, inputs, emacs-config, emacs-abyss-theme, nix-colors, nix-secrets, user, nixUserChroot ? false, ... }:

let
  name = "Matt Russell";
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
    ./ssh.nix
    ./emacs.nix
    ./terminals.nix
    ./tmux.nix
    ./darwin.nix
    ./gnome.nix
    ./age.nix
    ./llms.nix
    ./python-tooling.nix
  ];

  # Make shared variables available to all modules
  _module.args = {
    inherit name user homeDir nixPath emacs-config emacs-abyss-theme nix-secrets nixUserChroot;
  };

  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "26.05";

  colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;

  programs.home-manager.enable = true;

  # Ensure XDG_DATA_DIRS includes HM profile paths for GNOME app discovery
  targets.genericLinux.enable = isLinux;

  # Custom scripts
  home.file.".local/bin/sync-uv-tools" = {
    source = ../scripts/sync-uv-tools;
    executable = true;
  };

  home.file.".local/bin/claude-ide-external" = {
    source = ../scripts/claude-ide-external;
    executable = true;
  };

  # Enroot needs to know the Docker socket proxy path inside nix-user-chroot
  xdg.configFile."enroot/.env" = lib.mkIf nixUserChroot {
    text = "ENROOT_DOCKER_HOST=unix:///nix/tmp/docker-proxy.sock\n";
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };
}
