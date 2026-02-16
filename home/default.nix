{ config, pkgs, lib, inputs, emacs-config, emacs-abyss-theme, nix-colors, nix-secrets, hunspell-cy, ... }:

let
  name = "Matt Russell";
  user = "mtr21pqh";
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
    inherit name user email homeDir nixPath emacs-config emacs-abyss-theme nix-secrets hunspell-cy;
  };

  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "26.05";

  colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Custom scripts
  home.file.".local/bin/sync-uv-tools" = {
    source = ../scripts/sync-uv-tools;
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
