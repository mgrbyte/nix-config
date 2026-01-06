{ config, pkgs, lib, emacs-config, ... }:

let
  user = "mtr21pqh";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared-files = import ../shared/files.nix { inherit config pkgs lib emacs-config; };
in
{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "23.11";

    packages = with pkgs; [
      # Core tools
      bat
      btop
      coreutils
      curl
      fd
      fzf
      htop
      jq
      ripgrep
      tree
      unzip
      wget

      # Development
      direnv
      gh
      git
      lazygit

      # Security
      age
      gnupg
      keychain

      # Languages
      clojure
      leiningen
    ];

    file = shared-files // {
      # Set keyboard layout with ctrl:nocaps for X sessions
      ".xprofile".text = ''
        # Swap Caps Lock to Ctrl
        which setxkbmap >/dev/null 2>&1 && setxkbmap -layout us -option ctrl:nocaps
      '';

      # Also set in .profile for non-X environments that source it
      ".profile".text = ''
        # Swap Caps Lock to Ctrl (for X sessions started from console)
        if [ -n "$DISPLAY" ]; then
          which setxkbmap >/dev/null 2>&1 && setxkbmap -layout us -option ctrl:nocaps
        fi
      '';
    };
  };

  programs = shared-programs // {
    home-manager.enable = true;
    gpg.enable = true;
  };
}
