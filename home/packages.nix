{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  home.packages = with pkgs; [
    # General packages for development and system management
    bash-completion
    bat
    btop
    coreutils
    direnv
    htop
    killall
    openssh
    sqlite
    wget
    zip

    # Encryption and security tools
    age
    age-plugin-yubikey
    gnupg
    keychain
    libfido2

    # Terminal
    alacritty

    # LLMs
    claude-code

    # Emacs
    emacs

    # Cloud-related tools and SDKs
    docker
    docker-compose

    # Media-related packages
    emacsPackages.nerd-icons
    emacsPackages.nerd-icons-completion
    emacsPackages.nerd-icons-dired
    emacsPackages.nerd-icons-ibuffer
    dejavu_fonts
    ffmpeg
    fd
    font-awesome
    hack-font
    nerd-fonts.hack
    noto-fonts
    noto-fonts-color-emoji

    # development tools / text utils
    awscli2
    curl
    difftastic
    fzf
    gh
    glab
    jq
    kubectl
    lazygit
    markdownlint-cli2
    nodejs_24
    ripgrep
    terraform
    tmux
    tree
    unrar
    unzip

    # Programming languages and runtimes
    go
    rustc
    cargo
    openjdk

    # Python packages
    python3
    virtualenv

    # Platform-specific pinentry
    (if isDarwin then pinentry_mac else pinentry-curses)
  ] ++ lib.optionals isDarwin ([
    pkgs.dockutil  # Dock management tool
  ] ++ (with inputs.nix-casks.packages.${pkgs.system}; [
    # macOS GUI applications via nix-casks
    visual-studio-code
    raycast
    google-chrome
    cursor
    postman
  ]));
}
