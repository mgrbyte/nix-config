{ config, pkgs, lib, homeDir, user, nix-secrets, nixUserChroot ? false, ... }:

{
  # Disable home-manager-secrets systemd service in nix-user-chroot
  # (systemd runs outside the chroot and can't see /nix/store paths)
  systemd.user.services.home-manager-secrets = lib.mkIf nixUserChroot (lib.mkForce {});
  secrets = {
    # The age identity file used to decrypt secrets
    identityPaths = [ "${homeDir}/.ssh/id_ed25519_agenix" ];

    # On macOS, /run doesn't exist - use a local directory instead
    mount = "${homeDir}/.secrets";

    # Define secrets from nix-secrets repo
    file = {
      "id_mgrbyte_github" = {
        source = "${nix-secrets}/id_mgrbyte_github.age";
        symlinks = [ "${homeDir}/.ssh/id_mgrbyte_github" ];
      };
      "id_ed25519_mtr21pqh" = {
        source = "${nix-secrets}/id_ed25519_mtr21pqh.age";
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.ssh/id_ed25519_mtr21pqh" ];
      };
      "ssh-config-work" = {
        source = "${nix-secrets}/ssh-config-work.age";
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.ssh/config_work" ];
      };
      "huggingface-token" = {
        source = "${nix-secrets}/huggingface-token.age";
        symlinks = [ "${homeDir}/.cache/huggingface/token" ];
      };
      "work-env" = {
        source = "${nix-secrets}/work.env.age";
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.work.env" ];
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
      "init-gitlab-sync-config" = {
        source = "${nix-secrets}/init-gitlab-sync-config.el.age";
        symlinks = lib.optionals (user == "mtr21pqh") [ "${homeDir}/.emacs.d/lisp/init-gitlab-sync-config.el" ];
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
  # Compares a hash of the private key content to detect actual changes
  # (agenix always touches the file, so mtime comparison is unreliable).
  # Only prompts for passphrase on first run or after secret rotation.
  home.activation.generateSshPubKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _regen_pub() {
      local priv="$1"
      local pub="$priv.pub"
      local hash_file="$pub.keyhash"
      if [[ -f "$priv" ]]; then
        local current_hash
        current_hash=$(${pkgs.coreutils}/bin/sha256sum "$priv" | cut -d' ' -f1)
        if [[ ! -f "$pub" ]] || [[ "$(cat "$hash_file" 2>/dev/null)" != "$current_hash" ]]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f "$priv" > "$pub"
          echo "$current_hash" > "$hash_file"
        fi
      fi
    }
    _regen_pub ${homeDir}/.ssh/id_mgrbyte_github
    ${lib.optionalString (user == "mtr21pqh") "_regen_pub ${homeDir}/.ssh/id_ed25519_mtr21pqh"}
  '';

  # Load SSH keys into agent (and macOS keychain) for git signing
  # Linux uses keychain in shell.nix instead
  home.activation.loadSshKeysToAgent = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter ["generateSshPubKeys"] ''
      ${lib.optionalString (user == "mtr21pqh") "/usr/bin/ssh-add --apple-use-keychain ${homeDir}/.ssh/id_ed25519_mtr21pqh 2>/dev/null || true"}
      /usr/bin/ssh-add --apple-use-keychain ${homeDir}/.ssh/id_mgrbyte_github 2>/dev/null || true
    ''
  );
}
