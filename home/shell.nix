{ config, pkgs, lib, homeDir, nixPath, user, nixUserChroot ? false, ... }:

let
  hmConfigName = "${user}-${lib.optionalString nixUserChroot "chroot-"}${pkgs.stdenv.hostPlatform.system}";
in

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autocd = true;
    enableCompletion = true;
    completionInit = if nixUserChroot
      then "autoload -U compinit && compinit -u"
      else "autoload -U compinit && compinit";
    cdpath = [ "~/github" "~/gitlab" ];

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

      # PATH - defined in default.nix (single source of truth)
      export PATH="${nixPath}"

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

      # UV package manager config
      export UV_CONFIG="$HOME/.config/uv/uv.toml"

      # Hunspell dictionaries (Welsh + English)
      export DICPATH="$HOME/.local/share/hunspell:${pkgs.hunspellDicts.en-gb-ise}/share/hunspell:${pkgs.hunspellDicts.cy_GB}/share/hunspell"

      # HuggingFace token
      if [[ -r "$HOME/.secrets/huggingface-token" ]]; then
        export HF_TOKEN="$(cat $HOME/.secrets/huggingface-token)"
      fi

    '';

    # Login shell config (.zprofile) - runs after /etc/zprofile's path_helper
    # which reorders PATH, pushing nix paths behind /usr/bin
    profileExtra = ''
      export PATH="${nixPath}"
    '';

    # Interactive shell config (.zshrc)
    initContent = ''
      # Auto-start tmux (consistent tab behaviour across macOS and Linux)
      if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && -z "$EMACS" && -z "$VIM" ]]; then
        tmux attach-session -t default 2>/dev/null || tmux new-session -s default
      fi
      # Don't suggest commands that start with space (security: space-prefixed commands are private)
      ZSH_AUTOSUGGEST_HISTORY_IGNORE="( *)"

      # Disable partial line marker (the % shown when output doesn't end with newline)
      PROMPT_EOL_MARK=""

      # Oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

      # Emacs helper
      e() { emacsclient -t "$@"; }

      # Recolour the terminal while SSH'd into a configured host, so remote
      # sessions look distinctly different. Two modes:
      #
      #  - Inside tmux: set the current tmux window's `window-style` background.
      #    This is per-tmux-window, so switching to a local window (C-n/C-p)
      #    shows its own colour while the remote window stays themed.
      #  - Outside tmux: recolour the whole Alacritty window via IPC.
      #
      # Alacritty IPC alone can't do this: it colours the entire OS window, and
      # all tmux windows share one OS window, so they'd all change together.
      #
      # The IPC live socket is derived from the running Alacritty PID, not from
      # $ALACRITTY_SOCKET/$ALACRITTY_WINDOW_ID: tmux caches those at server-start
      # and they go stale after an Alacritty restart (dead socket files linger),
      # so trusting them silently no-ops. -w -1 targets all windows of the live
      # instance, sidestepping the equally-stale cached window id.
      _ssh_host_in_config() {
        local _kw rest pat
        while read -r _kw rest; do
          [[ "''${_kw:l}" == host ]] || continue
          for pat in ''${(z)rest}; do
            [[ "$pat" == "*" || "$pat" == "!"* ]] && continue
            [[ "$1" == ''${~pat} ]] && return 0
          done
        done < "''${HOME}/.ssh/config"
        return 1
      }

      _alacritty_live_socket() {
        local pid sock
        for pid in ''${(f)"$(pgrep -x alacritty 2>/dev/null)"}; do
          sock="''${TMPDIR:-/tmp}/Alacritty-$pid.sock"
          [[ -S "$sock" ]] && { print -r -- "$sock"; return 0; }
        done
        return 1
      }

      ssh() {
        local bg="#102a2e" dest sock
        dest=$(command ssh -G "$@" 2>/dev/null | awk '$1=="host"{print $2; exit}')
        if [[ -z "$dest" ]] || ! _ssh_host_in_config "$dest"; then
          command ssh "$@"; return
        fi
        if [[ -n "$TMUX" ]]; then
          tmux set-window-option window-style "bg=$bg" 2>/dev/null
          {
            command ssh "$@"
          } always {
            tmux set-window-option -u window-style 2>/dev/null
          }
        elif command -v alacritty >/dev/null 2>&1 && sock=$(_alacritty_live_socket); then
          ALACRITTY_SOCKET="$sock" alacritty msg config -w -1 "colors.primary.background=\"$bg\"" 2>/dev/null
          {
            command ssh "$@"
          } always {
            ALACRITTY_SOCKET="$sock" alacritty msg config -w -1 --reset 2>/dev/null
          }
        else
          command ssh "$@"
        fi
      }

      hm-switch() {
        cd ${homeDir}/github/mgrbyte/nix-config || return
        nix flake update claude-code
        nix run home-manager -- switch --flake ".#${hmConfigName}"
      }

      # Home Manager emacs update functions
      hm-emacs-update() {
        cd ${homeDir}/github/mgrbyte/nix-config || return
        nix flake update emacs-config --commit-lock-file
        nix run home-manager -- switch --flake ".#${hmConfigName}"
        git push
        ${if pkgs.stdenv.isDarwin
          then "launchctl kickstart -k gui/$(id -u)/org.nix-community.home.emacs"
          else "systemctl --user restart emacs"}
      }

      hm-emacs-update-dev() {
        cd ${homeDir}/github/mgrbyte/nix-config || return
        nix flake lock --override-input emacs-config path:${homeDir}/github/mgrbyte/emacs.d --commit-lock-file
        nix run home-manager -- switch --flake ".#${hmConfigName}"
        git push
        ${if pkgs.stdenv.isDarwin
          then "launchctl kickstart -k gui/$(id -u)/org.nix-community.home.emacs"
          else "systemctl --user restart emacs"}
      }

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

      # SSH key management: load keys into agent from macOS Keychain
      # Keys are stored to keychain by age.nix loadSshKeysToAgent activation step
      # Must use /usr/bin/ssh-add (Apple's), not Nix ssh-add (no keychain support)
      # Linux: GNOME keyring daemon acts as SSH agent and handles key caching
      ${lib.optionalString pkgs.stdenv.isDarwin ''
      /usr/bin/ssh-add --apple-load-keychain 2>/dev/null
      ''}

      ${lib.optionalString (user == "mtr21pqh") ''
      # Load work environment (API keys)
      if [[ -e "$HOME/.work.env" ]]; then
        set -a
        source "$HOME/.work.env"
        set +a
      fi
      ''}

      # Check for broken uv tools (silent unless broken)
      if [[ -x "$HOME/.local/bin/sync-uv-tools" ]]; then
        broken=$("$HOME/.local/bin/sync-uv-tools" 2>/dev/null | grep "^Broken:" | cut -d: -f2 | tr -d ' ')
        if [[ -n "$broken" && "$broken" != "none" ]]; then
          echo "⚠ Broken uv tools detected. Run: sync-uv-tools"
        fi
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
      home-manager = "nix run home-manager -- --flake '${homeDir}/github/mgrbyte/nix-config'";

      # Ripgrep
      search = "rg -p --glob '!node_modules/*'";
      rg-clj = "search --type=clojure";
      rg-elisp = "search --type=elisp";
      rg-j2 = "search --type=jinja";
      rg-jsonl = "search --type=jsonl";
      rg-ini = "search --type=ini";
      rg-md = "search --type=markdown";
      rg-nix = "search --type=nix";
      rg-py = "search --type=python";
      rg-toml = "search --type=toml";
      rg-ts = "search --type=typescript";

      # Clipboard aliases (macOS compatibility)
      pbcopy = lib.mkIf pkgs.stdenv.isLinux "wl-copy";
      pbpaste = lib.mkIf pkgs.stdenv.isLinux "wl-paste";

      ls = "ls --color=auto";
      ll = "ls -lh";
      l = "ls -l";
      la = "ls -a";

      # difftastic
      diff = "difft";

      # Claude Code with Emacs IDE integration
      # Starts MCP server in Emacs daemon, then launches claude with IDE env vars
      claude-ide = "CLAUDE_CODE_SSE_PORT=$(emacsclient -e '(claude-code-ide-mcp-start (expand-file-name default-directory))' 2>/dev/null | tr -d '\"') ENABLE_IDE_INTEGRATION=true claude";
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };

  # Oh-my-posh prompt configuration
  home.file.".config/oh-my-posh/config.json".source = ../oh-my-posh.json;
}
