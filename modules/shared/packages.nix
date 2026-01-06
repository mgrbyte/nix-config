{ pkgs }:

with pkgs; [
  # General packages for development and system management
  bash-completion
  bat
  btop
  coreutils
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

  # Node.js development tools
  nodejs_24

  # Text and terminal utilities
  htop
  jetbrains-mono
  jq
  ripgrep
  stow  
  tree
  tmux
  unrar
  unzip
  zsh-powerlevel10k
  
  # Development tools
  curl
  gh
  terraform
  kubectl
  awscli2
  lazygit
  fzf
  direnv
  
  # Programming languages and runtimes
  go
  rustc
  cargo
  openjdk

  # Python packages
  python3
  virtualenv
]
