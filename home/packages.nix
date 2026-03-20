{ config, pkgs, lib, inputs, emacs-abyss-theme, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # Build abyss-theme from flake input
  abyss-theme-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "abyss-theme";
    version = "0.7.2";
    src = emacs-abyss-theme;
  };

  # Build claude-code.el from github (not in nixpkgs)
  claude-code-el-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "claude-code";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "stevemolitor";
      repo = "claude-code.el";
      rev = "main";
      sha256 = "sha256-ISlD6q1hceckry1Jd19BX1MfobHJxng5ulX2gq9f644=";
    };
    packageRequires = with pkgs.emacsPackages; [ inheritenv ];
  };

  # Build claude-code-ide.el from github (not in nixpkgs)
  claude-code-ide-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "main";
      sha256 = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    packageRequires = with pkgs.emacsPackages; [ websocket web-server transient ];
  };

  # vterm-anti-flicker-filter - reduces terminal flickering in vterm
  vterm-anti-flicker-filter-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "vterm-anti-flicker-filter";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "martinbaillie";
      repo = "vterm-anti-flicker-filter";
      rev = "main";
      sha256 = "sha256-sFPBDyvSu8yvUmfrmg82rjUzQRUvyY4pBIlhL4OYACY=";
    };
    packageRequires = with pkgs.emacsPackages; [ vterm ];
  };

  # Bundle Emacs with all packages (including custom ones)
  myEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (epkgs: [
    abyss-theme-pkg
    claude-code-el-pkg
    claude-code-ide-pkg
    vterm-anti-flicker-filter-pkg
  ] ++ (with epkgs; [
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
    eat
    flycheck
    flycheck-clj-kondo
    gist
    gptel
    mcp
    mcp-server-lib
    google-this
    helm
    helm-projectile
    inheritenv
    jinja2-mode
    js2-mode
    json-mode
    keyfreq
    lsp-mode
    lsp-ui
    magit
    markdown-mode
    nerd-icons
    nerd-icons-completion
    nerd-icons-dired
    nerd-icons-ibuffer
    nix-mode
    org
    org-mcp
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
    web-server
    websocket
    whitespace-cleanup-mode
    wucuo
    yaml-mode
    zygospore
  ]));
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

    # Emacs (bundled with all packages)
    myEmacs

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
  ] ++ lib.optionals isDarwin ([
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
