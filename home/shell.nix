{ config, pkgs, lib, homeDir, nixPath, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
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
      export DICPATH="$HOME/.local/share/hunspell:${pkgs.hunspellDicts.en-gb-ise}/share/hunspell"
    '';

    # Interactive shell config (.zshrc)
    initContent = ''
      # Don't suggest commands that start with space (security: space-prefixed commands are private)
      ZSH_AUTOSUGGEST_HISTORY_IGNORE="( *)"

      # Oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

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
      # Explicitly list keys since homeage symlinks don't work with grep
      # Use fixed socket path so emacs daemon can find it
      if command -v keychain &>/dev/null; then
        keychain --quick --quiet --nogui \
          --ssh-agent-socket ~/.ssh/agent.sock \
          ~/.ssh/id_ed25519_agenix \
          ~/.ssh/id_mtr21pqh_github \
          ~/.ssh/id_ed25519_mtr21pqh
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
      home-manager = "nix run home-manager -- --flake '${homeDir}/github/mgrbyte/nix-config'";
      hm-switch = "nix run home-manager -- switch --flake '${homeDir}/github/mgrbyte/nix-config#mtr21pqh'";
      hm-emacs-update = "cd ${homeDir}/github/mgrbyte/nix-config && nix run home-manager -- switch --flake '.#mtr21pqh' --override-input emacs-config path:${homeDir}/github/mgrbyte/emacs.d && launchctl kickstart -k gui/$(id -u)/org.nix-community.home.emacs";

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

      keychain = "keychain --nocolor";
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };

  # Oh-my-posh prompt configuration
  home.file.".config/oh-my-posh/config.json".source = ../oh-my-posh.json;
}
