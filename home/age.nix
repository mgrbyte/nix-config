{ config, pkgs, lib, homeDir, nix-secrets, hunspell-cy, ... }:

{
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
      "huggingface-token" = {
        source = "${nix-secrets}/huggingface-token.age";
        symlinks = [ "${homeDir}/.cache/huggingface/token" ];
      };
      "work-env" = {
        source = "${nix-secrets}/work.env.age";
        symlinks = [ "${homeDir}/.work.env" ];
      };
      "uv-config" = {
        source = "${nix-secrets}/uv.toml.age";
        symlinks = [ "${homeDir}/.config/uv/uv.toml" ];
      };
      "netrc-work" = {
        source = "${nix-secrets}/netrc-work.age";
        symlinks = [ "${homeDir}/.netrc" ];
      };
      "netrc-personal" = {
        source = "${nix-secrets}/netrc-personal.age";
      };
      "allowed-signers" = {
        source = "${nix-secrets}/allowed-signers.age";
        symlinks = [ "${homeDir}/.ssh/allowed_signers" ];
      };
    };
  };

  # Clojure deps.edn - development aliases and tools
  home.file.".clojure/deps.edn".source = ../config/deps.edn;

  # Welsh hunspell dictionary (from techiaith/hunspell-cy)
  home.file.".local/share/hunspell/cy_GB.dic".source = "${hunspell-cy}/cy_GB.dic";
  home.file.".local/share/hunspell/cy_GB.aff".source = "${hunspell-cy}/cy_GB.aff";

  # Secret rotation helper
  home.file.".local/bin/update-secret" = {
    source = ../scripts/update-secret;
    executable = true;
  };
}
