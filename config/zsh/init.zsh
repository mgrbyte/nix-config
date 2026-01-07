# Nix daemon
if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Define variables for directories
export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
export PATH=$HOME/.local/share/bin:$PATH

# Remove history data we don't want to see
export HISTIGNORE="pwd:ls:cd"

# Ripgrep alias
alias search=rg -p --glob '!node_modules/*' $@

# Emacs is my editor
export ALTERNATE_EDITOR=""
export EDITOR="emacsclient -t"
export VISUAL="emacs -Q -nw"

e() {
    emacsclient -t "$@"
}


# Use difftastic, syntax-aware diffing
alias diff=difft

# Sync starship config to dot-files repo for servers
sync-starship() {
  if [[ -d ~/github/mgrbyte/dot-files/starship ]]; then
    cp ~/.config/starship.toml ~/github/mgrbyte/dot-files/starship/starship.toml
    echo "Synced starship config to dot-files"
  else
    echo "dot-files/starship directory not found"
  fi
}

# Always color ls and group directories
alias ls='ls --color=auto'
alias ll='ls -lh'
alias l='ls -l'
alias la='ls -a'

# Grep aliases
alias rg-clj='rg --type=clojure'
alias rg-j2='rg --type=jinja'
alias rg-md='rg --type=markdown'
alias rg-py='rg --type=python'
alias rg-toml='rg --type=toml'
alias rg-ts='rg --type=typescript'

# Locale settings
export LANGUAGE="en_GB:en"
export LC_ALL="en_GB.UTF-8"
export LC_COLLATE="en_GB.UTF-8"
export LC_CTYPE="en_GB.UTF-8"
export LC_MESSAGES="en_GB.UTF-8"
export LESSCHARSET="utf-8"

# XDG base directory
export XDG_CONFIG_HOME="${HOME}/.config"

# direnv hook
eval "$(direnv hook zsh)"

# Completion settings
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# SSH completion - use known_hosts and config for host completion
zstyle ':completion:*:(ssh|scp|rsync):*' hosts-host-aliases yes
zstyle ':completion:*:(ssh|scp|rsync):*' hosts-ipaddr yes

# Emacs keybindings (C-a, C-e, C-k, M-f, M-b, M-d, etc.)
bindkey -e
# Additional keybindings
bindkey '^[^?' backward-kill-word  # M-DEL (Meta-Backspace) deletes word
bindkey '^[[3;3~' kill-word        # M-Del (forward) deletes word forward

# Treat path segments as separate words (so Ctrl-W deletes one segment, not whole path)
WORDCHARS=${WORDCHARS/\//}

# SSH key management via keychain
if command -v keychain &>/dev/null; then
    ssh_private_keys=$(grep -slR "PRIVATE" ~/.ssh/)
    keychain --quick --quiet --nogui ${ssh_private_keys}
    unset ssh_private_keys
    source ${HOME}/.keychain/$(hostname)-sh
fi

# Load work environment (API keys)
if [ -e "${HOME}/.work.env" ]; then
    source "${HOME}/.work.env"
fi

# Auto-sync starship config to dot-files on login
sync-starship >/dev/null 2>&1

# Load completion settings
source "${XDG_CONFIG_HOME}/zsh/completion.zsh"
