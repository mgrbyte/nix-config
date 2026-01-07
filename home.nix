{ config, pkgs, lib, inputs, emacs-config, ... }:

let
  name = "Matt Russell";
  user = "mtr21pqh";
  email = "m.russell@bangor.ac.uk";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.username = user;
  home.homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # Allow unfree packages (claude-code)
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # PACKAGES
  # ==========================================================================
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
    starship
    wget
    zip

    # Encryption and security tools
    age
    age-plugin-yubikey
    gnupg
    keychain
    libfido2

    # LLMs
    claude-code

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
    zsh-prezto

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
  ] ++ lib.optionals isDarwin (with inputs.nix-casks.packages.${pkgs.system}; [
    # macOS GUI applications via nix-casks
    visual-studio-code
    iterm2
    raycast
    google-chrome
    cursor
    postman
  ]);

  # ==========================================================================
  # FILES
  # ==========================================================================
  home.file = {
    # Clojure deps.edn - development aliases and tools
    ".clojure/deps.edn".source = ./config/deps.edn;

    # Emacs configuration from github:mgrbyte/emacs.d
    ".emacs.d/init.el".source = "${emacs-config}/init.el";
    ".emacs.d/lisp" = {
      source = "${emacs-config}/lisp";
      recursive = true;
    };

    # ZSH configuration
    ".config/zsh/init.zsh".source = ./config/zsh/init.zsh;
    ".config/zsh/completion.zsh".source = ./config/zsh/completion.zsh;

    # GPG agent configuration with nix-managed pinentry path
    ".gnupg/gpg-agent.conf".text = ''
      enable-ssh-support
      default-cache-ttl 34560000
      max-cache-ttl 34560000
      pinentry-program ${if isDarwin
        then "${pkgs.pinentry_mac}/bin/pinentry-mac"
        else "${pkgs.pinentry-curses}/bin/pinentry-curses"}
      allow-emacs-pinentry
    '';
  };

  # ==========================================================================
  # PROGRAMS
  # ==========================================================================

  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    cdpath = [ "~/Projects" ];
    plugins = [];
    initContent = lib.mkBefore ''
      source "${config.home.homeDirectory}/.config/zsh/init.zsh"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$python$custom$nix_shell$character";
      add_newline = false;

      character = {
        success_symbol = "[󰅂](bold #00ff7f)";
        error_symbol = "[󰅂](bold #ff0000)";
      };

      directory = {
        truncation_length = 1;
        truncate_to_repo = false;
        format = "[$path]($style) ";
        style = "bold #cd69c9";
      };

      git_branch = {
        format = "[$symbol $branch]($style) ";
        symbol = "󰘬";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        stashed = "[󱓢](#f4c430)";
        staged = "[󰐕](#a2ff76)";
        modified = "[](#9c6f44)";
        deleted = "[󰆴](#ff9933)";
        renamed = "[󰑕](#ee0000)";
        untracked = "[](#ffddca)";
        conflicted = "[󱈸](#b87333)";
        ahead = "[󱖘\${count}](#ffbf00)";
        behind = "[󱖚\${count}](#a2a2d0)";
        diverged = "[󱡷](#edc9af)";
      };

      hostname = {
        ssh_only = true;
        format = "[$user][󰁥][$hostname]($style)";
        style = "bold #edc9af";
      };

      python = {
        format = "[$symbol]($style) ";
        symbol = "󰌠";
        detect_files = [ "pyproject.toml" "setup.py" "setup.cfg" "__init__.py" ];
        detect_extensions = [ "py" ];
        detect_folders = [ ".venv" "venv" ];
      };

      custom.elisp = {
        command = "printf '\\ue7cf'";
        when = "test -f init.el || ls *.el 1>/dev/null 2>&1";
        format = "[$output]($style) ";
        style = "#f0ead6";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      "*.swp"
      "*~"
      ".dir-locals.el"
      ".serena/"
      ".idea/**/workspace.xml"
      ".idea/**/tasks.xml"
      ".idea/**/usage.statistics.xml"
      ".idea/**/dictionaries"
      ".idea/**/shelf"
      ".idea/**/aws.xml"
      ".idea/**/contentModel.xml"
      ".idea/**/dataSources/"
      ".idea/**/dataSources.ids"
      ".idea/**/dataSources.local.xml"
      ".idea/**/sqlDataSources.xml"
      ".idea/**/dynamic.xml"
      ".idea/**/uiDesigner.xml"
      ".idea/**/dbnavigator.xml"
      ".idea/**/gradle.xml"
      ".idea/**/libraries"
      ".idea/**/mongoSettings.xml"
      ".idea_modules/"
      ".idea/**/sonarlint/"
      ".idea/sonarlint.xml"
      ".idea/httpRequests"
      "*.iws"
      "out/"
      "atlassian-ide-plugin.xml"
      ".idea/replstate.xml"
      "com_crashlytics_export_strings.xml"
      "crashlytics.properties"
      "crashlytics-build.properties"
      "fabric.properties"
      "http-client.private.env.json"
      ".idea/caches/build_file_checksums.ser"
      ".vscode/*"
      "!.vscode/settings.json"
      "!.vscode/tasks.json"
      "!.vscode/launch.json"
      "!.vscode/extensions.json"
      "!.vscode/*.code-snippets"
      "*.vsix"
    ];
    settings = {
      user = {
        name = name;
        email = email;
        signingkey = "AC61E672F0A921B7";
      };
      alias = {
        ci = "commit";
        chp = "cherry-pick";
      };
      init.defaultBranch = "main";
      core = {
        editor = "emacsclient -t";
        autocrlf = "input";
      };
      commit.gpgsign = true;
      tag.gpgsign = true;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      (if isLinux then "/home/${user}/.ssh/config_external" else "/Users/${user}/.ssh/config_external")
    ];
    matchBlocks = {
      "*" = {
        sendEnv = [ "LANG" "LC_*" ];
        hashKnownHosts = true;
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (if isLinux then "/home/${user}/.ssh/id_mtr21pqh_github" else "/Users/${user}/.ssh/id_mtr21pqh_github")
        ];
      };
    };
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
           set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
  };

  # ==========================================================================
  # NIX SETTINGS
  # ==========================================================================
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  # ==========================================================================
  # DARWIN-ONLY: Emacs daemon via launchd
  # ==========================================================================
  launchd.agents.emacs = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.emacs}/bin/emacs" "--daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.err";
    };
  };
}
