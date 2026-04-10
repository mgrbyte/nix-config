{ config, pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Use a proper systemd ssh-agent instead of GCR's ssh component.
  # GCR's ssh-agent intercepts sign requests and calls ensure_key() which
  # spawns a GUI prompt via gcr-ssh-askpass; from a headless context (Emacs
  # daemon systemd service) that prompt never appears and ssh-keygen -Y sign
  # hangs forever.  The home-manager ssh-agent service sets SSH_AUTH_SOCK via
  # systemd --user set-environment so ALL user services including the Emacs
  # daemon get the correct socket without needing a display.
  services.ssh-agent.enable = true;

  # Prevent GCR from claiming the SSH agent role at login.
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=SSH Key Agent
    Hidden=true
  '';

  # Remap Caps Lock to Ctrl in GNOME
  dconf.settings."org/gnome/desktop/input-sources" = {
    xkb-options = [ "ctrl:nocaps" ];
  };

  # focus-window@mgrbyte GNOME Shell extension
  # Exposes org.mgrbyte.FocusWindow D-Bus interface so Emacs can focus
  # Alacritty after launching a Claude session (org.gnome.Shell.Eval is
  # disabled in GNOME 45+ and FocusApp is access-denied).
  home.file.".local/share/gnome-shell/extensions/focus-window@mgrbyte/extension.js" = {
    source = ../config/gnome-extensions + "/focus-window@mgrbyte/extension.js";
  };
  home.file.".local/share/gnome-shell/extensions/focus-window@mgrbyte/metadata.json" = {
    source = ../config/gnome-extensions + "/focus-window@mgrbyte/metadata.json";
  };

  # Add extension to dconf enabled-extensions list without clobbering other
  # extensions the user may have enabled via GNOME Settings.
  # The extension activates on next GNOME Shell start (logout/login required
  # after initial install; subsequent home-manager switches are instant).
  home.activation.enableFocusWindowExtension = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v dconf >/dev/null 2>&1 && [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      uuid="focus-window@mgrbyte"
      current=$(dconf read /org/gnome/shell/enabled-extensions 2>/dev/null || echo "")
      if [ -z "$current" ] || [ "$current" = "@as []" ]; then
        dconf write /org/gnome/shell/enabled-extensions "['$uuid']"
      elif [[ "$current" != *"$uuid"* ]]; then
        new="''${current%]}, '$uuid']"
        dconf write /org/gnome/shell/enabled-extensions "$new"
      fi
    fi
  '';

  # dev-tools: launch Alacritty + Emacsclient and tile side by side.
  # Linux equivalent of dev-tools.app on macOS.
  home.file.".local/bin/dev-tools" = {
    source = ../scripts/dev-tools;
    executable = true;
  };

  xdg.desktopEntries.dev-tools = {
    name = "dev-tools";
    genericName = "Development Environment";
    comment = "Launch Alacritty and Emacsclient tiled side by side";
    exec = "${config.home.homeDirectory}/.local/bin/dev-tools";
    icon = "emacs";
    type = "Application";
    categories = [ "Development" "Utility" ];
  };
}
