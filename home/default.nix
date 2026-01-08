{ config, pkgs, lib, inputs, emacs-config, nix-colors, nix-secrets, ... }:

let
  name = "Matt Russell";
  user = "mtr21pqh";
  email = "m.russell@bangor.ac.uk";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDir = if isDarwin then "/Users/${user}" else "/home/${user}";
  nixPath = "${homeDir}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
  ];

  # Make shared variables available to all modules
  _module.args = {
    inherit name user email homeDir nixPath emacs-config nix-secrets;
  };

  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "26.05";

  colorScheme = nix-colors.colorSchemes.dracula;

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };
}
