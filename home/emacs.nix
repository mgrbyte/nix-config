{ config, pkgs, lib, homeDir, nixPath, emacs-config, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Clear stale native-compiled elisp on config change
  home.activation.clearElnCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    find ~/.emacs.d/eln-cache/ -type f -name '*mgrbyte*' -delete 2>/dev/null || true
  '';

  # Emacs configuration files from github:mgrbyte/emacs.d
  home.file = {
    ".emacs.d/init.el".source = "${emacs-config}/init.el";
    ".emacs.d/lisp" = {
      source = "${emacs-config}/lisp";
      recursive = true;
    };
    ".emacs.d/images" = {
      source = "${emacs-config}/images";
      recursive = true;
    };
  };

  # Emacs daemon via launchd (macOS only)
  launchd.agents.emacs = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.profileDirectory}/bin/emacs" "--fg-daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.err";
      EnvironmentVariables = {
        PATH = nixPath;
        CLAUDE_TIPS_FILE = "${homeDir}/.claude/tips.txt";
        # SSH_AUTH_SOCK inherited from launchd (macOS native ssh-agent)
      };
    };
  };

  # Emacsclient desktop entry (Linux only; macOS uses darwin.nix createEmacsclientApp)
  xdg.desktopEntries.emacsclient = lib.mkIf (pkgs.stdenv.isLinux) {
    name = "Emacsclient";
    genericName = "Text Editor";
    comment = "Connect to Emacs daemon";
    exec = "${config.home.profileDirectory}/bin/emacsclient -c %F";
    icon = "emacs";
    type = "Application";
    categories = [ "Development" "TextEditor" "Utility" ];
  };

  # Emacs daemon via systemd (Linux only)
  systemd.user.services.emacs = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Emacs daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${config.home.profileDirectory}/bin/emacs --fg-daemon";
      ExecStop = "${config.home.profileDirectory}/bin/emacsclient --eval \"(kill-emacs)\"";
      Restart = "on-failure";
      Environment = [
        "PATH=${nixPath}"
        "CLAUDE_TIPS_FILE=${homeDir}/.claude/tips.txt"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
