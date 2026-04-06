{ config, pkgs, lib, inputs, emacs-abyss-theme, emacs-tokyo-theme, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  casks = inputs.nix-casks.packages.${pkgs.stdenv.hostPlatform.system};

  # Cross-platform GUI apps: listed separately per platform to avoid
  # nix-casks broken bin/ wrapper symlinks on macOS.

  # Build abyss-theme from flake input
  abyss-theme-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "abyss-theme";
    version = "0.7.2";
    src = emacs-abyss-theme;
  };

  # Build tokyo-night themes from flake input (bbatsov)
  tokyo-theme-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "tokyo-night-themes";
    version = "0.1.0";
    src = emacs-tokyo-theme;
    files = [ "*.el" ];
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
      sha256 = "sha256-qH1QnG5G+0UiH/v0KaS7oSpQZY+BkUMZvrjbx6kyFhg=";
    };
    packageRequires = with pkgs.emacsPackages; [ websocket web-server transient ];
  };

  # emacs-mcp-server - MCP server exposing Emacs to Claude Code
  emacs-mcp-server-pkg = pkgs.emacsPackages.trivialBuild {
    pname = "emacs-mcp-server";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "rhblind";
      repo = "emacs-mcp-server";
      rev = "main";
      sha256 = "sha256-3a9pXwa8o03Y4kFcHB+CqML7SwIb3+b1qOyOaB1QUL8=";
    };
    postUnpack = ''
      cp $sourceRoot/tools/*.el $sourceRoot/
    '';
    packageRequires = with pkgs.emacsPackages; [ mcp-server-lib ];
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
    tokyo-theme-pkg
    claude-code-el-pkg
    claude-code-ide-pkg
    emacs-mcp-server-pkg
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
    toml
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
    hunspellDicts.cy_GB

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
    socat
    terraform
    texliveFull
    tmux
    tree
    unrar
    unzip

    # Programming languages and runtimes
    go

    # Rust
    rustc
    cargo

    # Java
    openjdk

    # Python
    python3
    uv
    virtualenv

    # Platform-specific pinentry
    (if isDarwin then pinentry_mac else pinentry-curses)
  ] ++ lib.optionals isLinux [
    wl-clipboard
    pkgs.firefox
    pkgs.gimp-with-plugins
  ]
  ++ lib.optionals isDarwin ([
    pkgs.dockutil  # Dock management tool
  ] ++ (with casks; [
    firefox
    gimp
    # macOS-only GUI applications (no Linux equivalent wanted)
    visual-studio-code
    raycast
    google-chrome
    cursor
    postman
  ]));
}
