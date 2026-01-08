{ config, pkgs, lib, inputs, emacs-config, ... }:

let
  name = "Matt Russell";
  user = "mtr21pqh";
  email = "m.russell@bangor.ac.uk";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDir = if isDarwin then "/Users/${user}" else "/home/${user}";
  # PATH with nix-profile first - used by both .zshenv and launchd
  nixPath = "${homeDir}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
in
{
  home.username = user;
  home.homeDirectory = homeDir;
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

    # History settings (declarative - generates setopt commands)
    history = {
      size = 10000;
      save = 10000;
      share = true;                  # SHARE_HISTORY
      ignoreDups = true;             # HIST_IGNORE_DUPS
      ignoreAllDups = true;          # HIST_IGNORE_ALL_DUPS
      ignoreSpace = true;            # HIST_IGNORE_SPACE
      expireDuplicatesFirst = true;  # HIST_EXPIRE_DUPS_FIRST
      findNoDups = true;             # HIST_FIND_NO_DUPS
      saveNoDups = true;             # HIST_SAVE_NO_DUPS
    };

    # Environment variables (.zshenv) - sourced for ALL shells
    envExtra = ''
      # Nix daemon
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # PATH with nix-profile first
      export PATH="${nixPath}"
      export PATH="$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH"
      export PATH="$HOME/.npm-packages/bin:$HOME/bin:$PATH"
      export PATH="$HOME/.local/share/bin:$PATH"

      # Editor
      export ALTERNATE_EDITOR=""
      export EDITOR="emacsclient -t"
      export VISUAL="emacs -Q -nw"

      # Locale
      export LANGUAGE="en_GB:en"
      export LC_ALL="en_GB.UTF-8"
      export LC_COLLATE="en_GB.UTF-8"
      export LC_CTYPE="en_GB.UTF-8"
      export LC_MESSAGES="en_GB.UTF-8"
      export LESSCHARSET="utf-8"

      # XDG
      export XDG_CONFIG_HOME="$HOME/.config"
    '';

    # Interactive shell config (.zshrc)
    initContent = ''
      # Emacs helper
      e() { emacsclient -t "$@"; }

      # direnv hook
      eval "$(direnv hook zsh)"

      # Completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:(ssh|scp|rsync):*' hosts-host-aliases yes
      zstyle ':completion:*:(ssh|scp|rsync):*' hosts-ipaddr yes

      # Emacs keybindings
      bindkey -e
      bindkey '^[^?' backward-kill-word
      bindkey '^[[3;3~' kill-word
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # Treat path segments as separate words
      WORDCHARS=''${WORDCHARS/\//}

      # SSH key management via keychain
      if command -v keychain &>/dev/null; then
        ssh_private_keys=$(grep -slR "PRIVATE" ~/.ssh/)
        keychain --quick --quiet --nogui ''${ssh_private_keys}
        unset ssh_private_keys
        source ''${HOME}/.keychain/$(hostname)-sh
      fi

      # Load work environment (API keys)
      if [[ -e "$HOME/.work.env" ]]; then
        source "$HOME/.work.env"
      fi

      # Auto-sync starship on login
      sync-starship >/dev/null 2>&1

      # === Completion options (from zprezto) ===
      setopt COMPLETE_IN_WORD
      setopt ALWAYS_TO_END
      setopt PATH_DIRS
      setopt AUTO_LIST
      setopt AUTO_PARAM_SLASH
      setopt EXTENDED_GLOB
      setopt MENU_COMPLETE
      unsetopt CASE_GLOB

      # Completion caching
      zstyle ':completion::complete:*' use-cache on
      zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/.zcompcache"

      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # Fuzzy match
      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric
      zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

      # Don't complete unavailable commands
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

      # Directories
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      zstyle ':completion:*' squeeze-slashes true

      # SSH/SCP/RSYNC completion
      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr

      # fzf-tab: preview directory contents when completing cd
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    '';

    shellAliases = {
      # Ripgrep
      search = "rg -p --glob '!node_modules/*'";
      rg-clj = "rg --type=clojure";
      rg-j2 = "rg --type=jinja";
      rg-md = "rg --type=markdown";
      rg-py = "rg --type=python";
      rg-toml = "rg --type=toml";
      rg-ts = "rg --type=typescript";

      # ls
      ls = "ls --color=auto";
      ll = "ls -lh";
      l = "ls -l";
      la = "ls -a";

      # difftastic
      diff = "difft";
    };

    # Antidote plugin manager
    antidote = {
      enable = true;
      plugins = [
        "zsh-users/zsh-autosuggestions"
        "Aloxaf/fzf-tab"
        "ohmyzsh/ohmyzsh path:lib/git.zsh"
      ];
    };
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
      ".idea/**/aws.xml"
      ".idea/**/contentModel.xml"
      ".idea/**/dataSources.ids"
      ".idea/**/dataSources.local.xml"
      ".idea/**/dataSources/"
      ".idea/**/dbnavigator.xml"
      ".idea/**/dictionaries"
      ".idea/**/dynamic.xml"
      ".idea/**/gradle.xml"
      ".idea/**/libraries"
      ".idea/**/mongoSettings.xml"
      ".idea/**/shelf"
      ".idea/**/sonarlint/"
      ".idea/**/sqlDataSources.xml"
      ".idea/**/tasks.xml"
      ".idea/**/uiDesigner.xml"
      ".idea/**/usage.statistics.xml"
      ".idea/**/workspace.xml"
      ".idea/httpRequests"
      ".idea/replstate.xml"
      ".idea/sonarlint.xml"
      ".idea_modules/"
      "*.iws"
      "out/"
      "atlassian-ide-plugin.xml"
      "com_crashlytics_export_strings.xml"
      "crashlytics-build.properties"
      "crashlytics.properties"
      "fabric.properties"
      "http-client.private.env.json"
      ".idea/caches/build_file_checksums.ser"
      ".vscode/*"
      "!.vscode/*.code-snippets"
      "!.vscode/extensions.json"
      "!.vscode/launch.json"
      "!.vscode/settings.json"
      "!.vscode/tasks.json"
      "*.vsix"
    ];
    settings = {
      user = {
        name = name;
        email = email;
        signingkey = "AC61E672F0A921B7";
      };
      alias = {
        br = "branch";
        cb = "checkout -b";
        chp = "cherry-pick";
        ci = "commit";
        co = "checkout";
        db = "branch -D";
        df = "diff";
        diff-all = "difftool -y -d";
        llog = "log --oneline --graph";
        log-unpushed = "log --no-merges";
        lp = "log -p";
        mnf = "merge --no-ff";
        rh = "reset --hard";
        rhh = "reset --hard HEAD";
        rn = "branch -m";
        rpo = "remote prune origin";
        sl = "stash list";
        st = "status -uno";
        whatadded = "log --diff-filter=A";
      };
      init.defaultBranch = "main";
      push.default = "simple";
      core = {
        editor = "emacsclient -t";
        autocrlf = "input";
      };
      # Credential helper for Techiaith storfa
      "credential \"https://storfa.techiaith.cymru\"" = {
        username = "oauth";
        helper = "netrc";
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
      EnvironmentVariables = {
        PATH = nixPath;
      };
    };
  };
}
