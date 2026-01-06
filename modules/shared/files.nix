{ pkgs, config, lib, emacs-config, ... }:

{
  # Clojure deps.edn - development aliases and tools
  ".clojure/deps.edn".source = ./config/deps.edn;

  # Emacs configuration from github:mgrbyte/emacs.d
  ".emacs.d/init.el".source = "${emacs-config}/init.el";
  ".emacs.d/lisp" = {
    source = "${emacs-config}/lisp";
    recursive = true;
  };

  # GPG agent configuration with nix-managed pinentry path (platform-conditional)
  ".gnupg/gpg-agent.conf".text = ''
    enable-ssh-support
    default-cache-ttl 34560000
    max-cache-ttl 34560000
    pinentry-program ${if pkgs.stdenv.hostPlatform.isDarwin
      then "${pkgs.pinentry_mac}/bin/pinentry-mac"
      else "${pkgs.pinentry-curses}/bin/pinentry-curses"}
    allow-emacs-pinentry
  '';
}
