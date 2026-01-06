{ config, pkgs, agenix, secrets, ... }:

let user = "mtr21pqh"; in
{
  age.identityPaths = [
    "/Users/${user}/.ssh/id_ed25519_agenix"
  ];

  # GitHub SSH key
  age.secrets."id_mtr21pqh_github" = {
    symlink = true;
    path = "/Users/${user}/.ssh/id_mtr21pqh_github";
    file = "${secrets}/id_mtr21pqh_github.age";
    mode = "600";
    owner = "${user}";
    group = "staff";
  };

  # Main SSH key
  age.secrets."id_ed25519_mtr21pqh" = {
    symlink = true;
    path = "/Users/${user}/.ssh/id_ed25519_mtr21pqh";
    file = "${secrets}/id_ed25519_mtr21pqh.age";
    mode = "600";
    owner = "${user}";
    group = "staff";
  };

  # Work environment (API keys)
  age.secrets."work.env" = {
    symlink = true;
    path = "/Users/${user}/.work.env";
    file = "${secrets}/work.env.age";
    mode = "600";
    owner = "${user}";
    group = "staff";
  };

  # HuggingFace token
  age.secrets."huggingface-token" = {
    symlink = true;
    path = "/Users/${user}/.cache/huggingface/token";
    file = "${secrets}/huggingface-token.age";
    mode = "600";
    owner = "${user}";
    group = "staff";
  };

  # GPG private key
  age.secrets."gpg-private-key" = {
    symlink = false;
    path = "/Users/${user}/.gnupg/private-keys-v1.d/gpg-private.key";
    file = "${secrets}/gpg-private-key.age";
    mode = "600";
    owner = "${user}";
    group = "staff";
  };
}
