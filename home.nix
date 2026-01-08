{ config, pkgs, lib, inputs, emacs-config, nix-colors, ... }:

let
  name = "Matt Russell";
  user = "mtr21pqh";
  email = "m.russell@bangor.ac.uk";
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDir = if isDarwin then "/Users/${user}" else "/home/${user}";
  # PATH with nix-profile first - used by both .zshenv and launchd
  nixPath = "${homeDir}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  # Helper to convert hex color to iTerm2 plist format (RGB 0.0-1.0)
  hexToIterm = hex: let
    r = builtins.substring 0 2 hex;
    g = builtins.substring 2 2 hex;
    b = builtins.substring 4 2 hex;
    hexToDec = h: let
      chars = lib.stringToCharacters h;
      hexDigit = c:
        if c == "a" || c == "A" then 10
        else if c == "b" || c == "B" then 11
        else if c == "c" || c == "C" then 12
        else if c == "d" || c == "D" then 13
        else if c == "e" || c == "E" then 14
        else if c == "f" || c == "F" then 15
        else lib.strings.toInt c;
    in (hexDigit (builtins.elemAt chars 0)) * 16 + (hexDigit (builtins.elemAt chars 1));
    toFloat = n: "${toString n}.0";
    normalize = n: "${toString (n / 255.0)}";
  in {
    red = normalize (hexToDec r);
    green = normalize (hexToDec g);
    blue = normalize (hexToDec b);
  };

  # Generate an iTerm2 color entry
  itermColorEntry = name: hex: let
    c = hexToIterm hex;
  in ''
    <key>${name}</key>
    <dict>
      <key>Alpha Component</key>
      <real>1</real>
      <key>Blue Component</key>
      <real>${c.blue}</real>
      <key>Color Space</key>
      <string>sRGB</string>
      <key>Green Component</key>
      <real>${c.green}</real>
      <key>Red Component</key>
      <real>${c.red}</real>
    </dict>
  '';
in
{
  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "26.05";

  # Disable copyApps - requires App Management permission which is problematic
  # Living with shortcut arrow on dock icons instead
  targets.darwin.copyApps.enable = false;

  # Note: With stateVersion >= 26.05 and xdg.enable = true, zsh config moves to ~/.config/zsh

  # Color scheme from nix-colors (base16)
  # See available schemes: https://github.com/tinted-theming/schemes
  colorScheme = nix-colors.colorSchemes.dracula;

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
    iterm2
    raycast
    google-chrome
    cursor
    postman
  ]));

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

    # Alacritty terminal config with nix-colors
    ".config/alacritty/alacritty.toml".text = let
      p = config.colorScheme.palette;
    in ''
      # Window configuration
      [window]
      dimensions = { columns = 207, lines = 58 }
      padding = { x = 12, y = 12 }
      decorations = "Full"
      opacity = 1.0
      option_as_alt = "Both"
      startup_mode = "Windowed"

      # Font configuration
      [font]
      size = 14.0

      [font.normal]
      family = "Hack Nerd Font"
      style = "Regular"

      [font.bold]
      family = "Hack Nerd Font"
      style = "Bold"

      [font.italic]
      family = "Hack Nerd Font"
      style = "Italic"

      # Colors from nix-colors (${config.colorScheme.slug})
      [colors.primary]
      background = "#${p.base00}"
      foreground = "#${p.base05}"

      [colors.cursor]
      text = "#${p.base00}"
      cursor = "#${p.base05}"

      [colors.selection]
      text = "#${p.base05}"
      background = "#${p.base02}"

      [colors.normal]
      black = "#${p.base00}"
      red = "#${p.base08}"
      green = "#${p.base0B}"
      yellow = "#${p.base0A}"
      blue = "#${p.base0D}"
      magenta = "#${p.base0E}"
      cyan = "#${p.base0C}"
      white = "#${p.base05}"

      [colors.bright]
      black = "#${p.base03}"
      red = "#${p.base08}"
      green = "#${p.base0B}"
      yellow = "#${p.base0A}"
      blue = "#${p.base0D}"
      magenta = "#${p.base0E}"
      cyan = "#${p.base0C}"
      white = "#${p.base07}"

      # Scrolling
      [scrolling]
      history = 10000
      multiplier = 3

      # Selection
      [selection]
      save_to_clipboard = true
    '';

    # iTerm2 color scheme from nix-colors (dracula)
    # Import in iTerm2: Preferences → Profiles → Colors → Color Presets → Import
    ".config/iterm2/nix-colors.itermcolors".text = let
      p = config.colorScheme.palette;
    in ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        ${itermColorEntry "Ansi 0 Color" p.base00}
        ${itermColorEntry "Ansi 1 Color" p.base08}
        ${itermColorEntry "Ansi 2 Color" p.base0B}
        ${itermColorEntry "Ansi 3 Color" p.base0A}
        ${itermColorEntry "Ansi 4 Color" p.base0D}
        ${itermColorEntry "Ansi 5 Color" p.base0E}
        ${itermColorEntry "Ansi 6 Color" p.base0C}
        ${itermColorEntry "Ansi 7 Color" p.base05}
        ${itermColorEntry "Ansi 8 Color" p.base03}
        ${itermColorEntry "Ansi 9 Color" p.base08}
        ${itermColorEntry "Ansi 10 Color" p.base0B}
        ${itermColorEntry "Ansi 11 Color" p.base0A}
        ${itermColorEntry "Ansi 12 Color" p.base0D}
        ${itermColorEntry "Ansi 13 Color" p.base0E}
        ${itermColorEntry "Ansi 14 Color" p.base0C}
        ${itermColorEntry "Ansi 15 Color" p.base07}
        ${itermColorEntry "Background Color" p.base00}
        ${itermColorEntry "Badge Color" p.base0E}
        ${itermColorEntry "Bold Color" p.base06}
        ${itermColorEntry "Cursor Color" p.base05}
        ${itermColorEntry "Cursor Guide Color" p.base02}
        ${itermColorEntry "Cursor Text Color" p.base00}
        ${itermColorEntry "Foreground Color" p.base05}
        ${itermColorEntry "Link Color" p.base0D}
        ${itermColorEntry "Selected Text Color" p.base05}
        ${itermColorEntry "Selection Color" p.base02}
      </dict>
      </plist>
    '';

    # Powerlevel10k prompt configuration
    ".p10k.zsh".source = ./p10k.zsh;
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
      # Powerlevel10k prompt config
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

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

      # === Completion options (from zprezto) ===
      setopt IGNORE_EOF           # Prevent accidental shell exit from Ctrl+D / M-d overflow
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
      # Home Manager (flake-based)
      home-manager = "nix run home-manager -- --flake ~/github/mgrbyte/nix-config";
      hm-switch = "home-manager switch --flake ~/github/mgrbyte/nix-config#mtr21pqh";

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
        "romkatv/powerlevel10k"
        "zsh-users/zsh-autosuggestions"
        "Aloxaf/fzf-tab"
        "ohmyzsh/ohmyzsh path:lib/git.zsh"
      ];
    };
  };

  # Starship disabled while trying p10k - kept for fallback
  programs.starship = {
    enable = false;  # Disable to let p10k handle prompt
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
        format = "[\\[$all_status$ahead_behind\\]]($style) ";
        stashed = "[ 󰏗](#f4c430)";
        staged = "[ 󰄬](#a2ff76)";
        modified = "[ 󰏫](#daa520)";
        deleted = "[ 󰅖](#ff9933)";
        renamed = "[ 󰑕](#ee0000)";
        untracked = "[ ?](#ffa500)";
        conflicted = "[ 󰘬](#b87333)";
        ahead = "[ 󰁔\${count}](#ffbf00)";
        behind = "[ 󰁍\${count}](#a2a2d0)";
        diverged = "[ 󰃻](#edc9af)";
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
  # DARWIN-ONLY: Install Karabiner-Elements via Homebrew (needs system drivers)
  # ==========================================================================
  home.activation.installKarabiner = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Karabiner needs system drivers that only the official installer provides
      BREW="/opt/homebrew/bin/brew"
      if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "/Applications/Karabiner-Elements.app/Contents/Info.plist" 2>/dev/null | grep -q "org.pqrs.Karabiner-Elements"; then
        if [[ -x "$BREW" ]]; then
          echo "Installing Karabiner-Elements via Homebrew..."
          "$BREW" install --cask karabiner-elements || true
        else
          echo "WARNING: Karabiner-Elements requires Homebrew installation."
          echo "Install Homebrew first, then run: brew install --cask karabiner-elements"
        fi
      fi
    ''
  );

  # Note: Karabiner config is NOT managed by nix (triggers keyboard dialog on each change)
  # Config lives at ~/.config/karabiner/karabiner.json - edit manually if needed
  # Current mappings: Cmd+f/b/d/u/l/y/./,/</> -> Meta equivalents in terminals

  # ==========================================================================
  # DARWIN-ONLY: Create Spotlight-indexable aliases for nix apps
  # ==========================================================================
  home.activation.createAppAliases = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create Finder aliases in /Applications so Spotlight can find nix apps
      for app in Alacritty Emacs; do
        if [[ -e "$HOME/.nix-profile/Applications/$app.app" ]]; then
          # Remove existing aliases (handles both "App.app" and "App.app alias" variants)
          rm -f "/Applications/$app.app" "/Applications/$app.app alias" 2>/dev/null || true
          # Create new Finder alias (Finder may add " alias" suffix)
          /usr/bin/osascript -e "tell application \"Finder\" to make alias file to POSIX file \"$HOME/.nix-profile/Applications/$app.app\" at POSIX file \"/Applications\"" >/dev/null 2>&1 || true
          # Rename if Finder added " alias" suffix
          if [[ -e "/Applications/$app.app alias" ]]; then
            mv "/Applications/$app.app alias" "/Applications/$app.app"
          fi
        fi
      done
    ''
  );

  # ==========================================================================
  # DARWIN-ONLY: Create Emacsclient.app wrapper (real files, not symlinks)
  # ==========================================================================
  home.activation.createEmacsclientApp = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      APP_DIR="$HOME/Applications/Emacsclient.app"
      CONTENTS="$APP_DIR/Contents"

      # Create directory structure
      mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

      # Write Info.plist
      cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Emacsclient</string>
  <key>CFBundleIconFile</key>
  <string>Emacs</string>
  <key>CFBundleIdentifier</key>
  <string>org.gnu.Emacsclient</string>
  <key>CFBundleName</key>
  <string>Emacsclient</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
</dict>
</plist>
PLIST

      # Write executable (note: EMACSCLIENT_PATH is set by nix interpolation)
      EMACSCLIENT_PATH="${pkgs.emacs}/bin/emacsclient"
      cat > "$CONTENTS/MacOS/Emacsclient" << EXEC
#!/bin/bash
exec "$EMACSCLIENT_PATH" -c "\$@"
EXEC
      chmod +x "$CONTENTS/MacOS/Emacsclient"

      # Copy icon (real file, not symlink)
      cp -f "${pkgs.emacs}/Applications/Emacs.app/Contents/Resources/Emacs.icns" "$CONTENTS/Resources/Emacs.icns"

      # Touch the app to update modification time (helps with icon cache)
      touch "$APP_DIR"
    ''
  );

  # ==========================================================================
  # DARWIN-ONLY: Add apps to Dock
  # ==========================================================================
  home.activation.configureDock = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["createAppAliases" "createEmacsclientApp"] ''
      DOCKUTIL="${pkgs.dockutil}/bin/dockutil"
      CHANGED=0

      # Add Alacritty to dock (use actual nix-profile path, not alias)
      if ! "$DOCKUTIL" --find Alacritty >/dev/null 2>&1; then
        "$DOCKUTIL" --add "$HOME/.nix-profile/Applications/Alacritty.app" --no-restart >/dev/null 2>&1 || true
        CHANGED=1
      fi

      # Add Emacsclient from ~/Applications (Emacs runs as daemon, so only need client)
      if ! "$DOCKUTIL" --find Emacsclient >/dev/null 2>&1; then
        "$DOCKUTIL" --add "$HOME/Applications/Emacsclient.app" --no-restart >/dev/null 2>&1 || true
        CHANGED=1
      fi

      # Restart dock only if we made changes
      if [[ $CHANGED -eq 1 ]]; then
        killall Dock 2>/dev/null || true
      fi
    ''
  );

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
