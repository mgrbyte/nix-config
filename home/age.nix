{ config, pkgs, lib, homeDir, nix-secrets, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  secrets = {
    # The age identity file used to decrypt secrets
    identityPaths = [ "${homeDir}/.ssh/id_ed25519_agenix" ];

    # On macOS, /run doesn't exist - use a local directory instead
    mount = "${homeDir}/.secrets";

    # Define secrets from nix-secrets repo
    file = {
      "id_mtr21pqh_github" = {
        source = "${nix-secrets}/id_mtr21pqh_github.age";
        symlinks = [ "${homeDir}/.ssh/id_mtr21pqh_github" ];
      };
      "id_ed25519_mtr21pqh" = {
        source = "${nix-secrets}/id_ed25519_mtr21pqh.age";
        symlinks = [ "${homeDir}/.ssh/id_ed25519_mtr21pqh" ];
      };
      "ssh-config-external" = {
        source = "${nix-secrets}/ssh-config-external.age";
        symlinks = [ "${homeDir}/.ssh/config_external" ];
      };
      "gpg-private-key" = {
        source = "${nix-secrets}/gpg-private-key.age";
      };
      "huggingface-token" = {
        source = "${nix-secrets}/huggingface-token.age";
      };
      "work-env" = {
        source = "${nix-secrets}/work.env.age";
        symlinks = [ "${homeDir}/.work.env" ];
      };
    };
  };

  # Clojure deps.edn - development aliases and tools
  home.file.".clojure/deps.edn".source = ../config/deps.edn;

  # GPG agent configuration with nix-managed pinentry path
  home.file.".gnupg/gpg-agent.conf".text = ''
    enable-ssh-support
    default-cache-ttl 34560000
    max-cache-ttl 34560000
    pinentry-program ${if isDarwin
      then "${pkgs.pinentry_mac}/bin/pinentry-mac"
      else "${pkgs.pinentry-curses}/bin/pinentry-curses"}
    allow-emacs-pinentry
  '';
}
