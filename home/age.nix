{ config, pkgs, lib, homeDir, user, nix-secrets, ... }:

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
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.config/uv/uv.toml" ];
      };
      "work.netrc" = {
        source = "${nix-secrets}/work.netrc.age";
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.netrc" ];
      };
      "personal.netrc" = {
        source = "${nix-secrets}/personal.netrc.age";
        symlinks = lib.optionals (user == "mgrbyte") [ "${homeDir}/.netrc" ];
      };
      "allowed-signers" = {
        source = "${nix-secrets}/allowed-signers.age";
        symlinks = [ "${homeDir}/.ssh/allowed_signers" ];
      };
    };
  };

  # Clojure deps.edn - development aliases and tools
  home.file.".clojure/deps.edn".source = ../config/deps.edn;

  # Secret rotation helper
  home.file.".local/bin/update-secret" = {
    source = ../scripts/update-secret;
    executable = true;
  };

  # Regenerate SSH public keys from private keys on activation.
  # Only runs when the .pub is missing or older than the private key
  # (i.e. after secret rotation), avoiding passphrase prompts on every switch.
  home.activation.generateSshPubKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _regen_pub() {
      local priv="$1"
      local pub="$priv.pub"
      if [[ -f "$priv" ]] && { [[ ! -f "$pub" ]] || [[ "$priv" -nt "$pub" ]]; }; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f "$priv" > "$pub"
      fi
    }
    _regen_pub ${homeDir}/.ssh/id_mtr21pqh_github
    _regen_pub ${homeDir}/.ssh/id_ed25519_mtr21pqh
  '';

  # Load SSH keys into agent (and macOS keychain) for git signing
  # Linux uses keychain in shell.nix instead
  home.activation.loadSshKeysToAgent = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter ["generateSshPubKeys"] ''
      /usr/bin/ssh-add --apple-use-keychain ${homeDir}/.ssh/id_ed25519_mtr21pqh 2>/dev/null || true
      /usr/bin/ssh-add --apple-use-keychain ${homeDir}/.ssh/id_mtr21pqh_github 2>/dev/null || true
    ''
  );
}
