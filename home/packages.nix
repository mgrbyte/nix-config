{ config, pkgs, lib, inputs, emacs-abyss-theme, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # Build abyss-theme from flake input
  abyss-theme-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "abyss-theme";
    version = "0.7.2";
    src = emacs-abyss-theme;
  };
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
    ollama

    # Emacs
    emacs

    # Cloud-related tools and SDKs
    docker
    docker-compose


    # Media-related packages
    dejavu_fonts
    ffmpeg
    fd
    font-awesome
    hack-font
    nerd-fonts.hack
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji

    # Spell checking
    hunspell
    hunspellDicts.en-gb-ise

    # development tools / text utils
    awscli2
    cmake
    libtool
    curl
    difftastic
    fzf
    gh
    glab
    jq
    kubectl
    lazygit
    markdownlint-cli2
    pandoc
    nodejs_24
    oh-my-posh
    ripgrep
    terraform
    texliveFull
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
    uv
    virtualenv

    # Platform-specific pinentry
    (if isDarwin then pinentry_mac else pinentry-curses)
  ] ++ [
    # Emacs packages from flake inputs
    abyss-theme-pkg
  ] ++ (with pkgs.emacsPackages; [
    # Emacs packages - all managed by nix (not MELPA)
    clojure-mode
    company
    dash
    dashboard
    dirvish
    dockerfile-mode
    editorconfig
    envrc
    exec-path-from-shell
    f
    flycheck-clj-kondo
    gist
    google-this
    helm
    helm-projectile
    jinja2-mode
    js2-mode
    json-mode
    keyfreq
    lsp-mode
    lsp-pyright
    lsp-ui
    magit
    markdown-mode
    nerd-icons
    nerd-icons-completion
    nerd-icons-dired
    nerd-icons-ibuffer
    nix-mode
    org
    paredit
    powerline
    projectile
    py-snippets
    python-pytest
    rainbow-delimiters
    s
    sass-mode
    treemacs
    treemacs-magit
    treemacs-nerd-icons
    treemacs-projectile
    vcl-mode
    vterm
    vterm-toggle
    whitespace-cleanup-mode
    wucuo
    yaml-mode
    zygospore
  ]) ++ lib.optionals isDarwin ([
    pkgs.dockutil  # Dock management tool
  ] ++ (with inputs.nix-casks.packages.${pkgs.stdenv.hostPlatform.system}; [
    # macOS GUI applications via nix-casks
    visual-studio-code
    raycast
    google-chrome
    cursor
    postman
  ]));
}
