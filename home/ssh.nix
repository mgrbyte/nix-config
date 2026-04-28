{ config, pkgs, lib, user, homeDir, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = lib.optionals (user == "mtr21pqh") [
      (if isLinux then "/home/${user}/.ssh/config_work" else "/Users/${user}/.ssh/config_work")
    ];
    matchBlocks = {
      "*" = {
        sendEnv = [ "LANG" "LC_*" ];
        hashKnownHosts = true;
        addKeysToAgent = "yes";
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p.%C";
          ControlPersist = "600";
        };
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (if isLinux then "/home/${user}/.ssh/id_mgrbyte_github" else "/Users/${user}/.ssh/id_mgrbyte_github")
        ];
      };
    };
  };

  home.activation.ensureSshSocketsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${homeDir}/.ssh/sockets
  '';
}
