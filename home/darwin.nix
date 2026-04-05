{ config, pkgs, lib, homeDir, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Disable copyApps - requires App Management permission which is problematic
  # Living with shortcut arrow on dock icons instead
  targets.darwin.copyApps.enable = false;

  # Karabiner-Elements: Cmd -> Meta remapping for terminals
  # Installed manually (not via Nix or Homebrew)
  # Config lives at ~/.config/karabiner/karabiner.json - edit manually if needed
  # Current mappings: Cmd+f/b/d/u/l/y/./,/</> -> Meta equivalents in terminals

  # Hammerspoon: window tiling (installed manually, config managed by Nix)
  home.file.".hammerspoon/init.lua" = lib.mkIf isDarwin {
    source = ../config/hammerspoon/init.lua;
  };

  # Create Spotlight-indexable aliases for nix apps in ~/Applications
  # Using ~/Applications avoids JAMF/IT restrictions on /Applications
  home.activation.createAppAliases = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/Applications"
      for app_path in "$HOME/.nix-profile/Applications/"*.app; do
        [[ -e "$app_path" ]] || continue
        app=$(basename "$app_path")
        # Remove ALL existing aliases/files matching this app name
        find "$HOME/Applications" -maxdepth 1 -name "$app*" -exec rm -rf {} + 2>/dev/null || true
        # Resolve symlink - Finder requires the real nix store path, not the .nix-profile path
        real_path=$(readlink "$app_path")
        [[ -n "$real_path" ]] || real_path="$app_path"
        # Create new Finder alias (Finder may add " alias" suffix)
        /usr/bin/osascript -e "tell application \"Finder\" to make alias file to POSIX file \"$real_path\" at POSIX file \"$HOME/Applications\"" >/dev/null 2>&1 || true
        # Rename if Finder added " alias" or " alias N" suffix
        for alias_file in "$HOME/Applications/$app alias"*; do
          if [[ -e "$alias_file" ]]; then
            mv "$alias_file" "$HOME/Applications/$app"
            break
          fi
        done
      done
    ''
  );

  # Create Emacsclient.app wrapper (real files, not symlinks)
  home.activation.createEmacsclientApp = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      APP_DIR="$HOME/Applications/Emacsclient.app"
      CONTENTS="$APP_DIR/Contents"

      # Create directory structure
      mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

      # Write Info.plist
      cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Emacsclient</string>
  <key>CFBundleIconFile</key>
  <string>Emacs</string>
  <key>CFBundleIdentifier</key>
  <string>org.gnu.Emacsclient</string>
  <key>CFBundleName</key>
  <string>Emacsclient</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
</dict>
</plist>
PLIST

      # Write executable (note: EMACSCLIENT_PATH is set by nix interpolation)
      EMACSCLIENT_PATH="${pkgs.emacs}/bin/emacsclient"
      cat > "$CONTENTS/MacOS/Emacsclient" << EXEC
#!/bin/bash
exec "$EMACSCLIENT_PATH" -c "\$@"
EXEC
      chmod +x "$CONTENTS/MacOS/Emacsclient"

      # Copy icon (real file, not symlink)
      cp -f "${pkgs.emacs}/Applications/Emacs.app/Contents/Resources/Emacs.icns" "$CONTENTS/Resources/Emacs.icns"

      # Touch the app to update modification time (helps with icon cache)
      touch "$APP_DIR"
    ''
  );

  # Create dev-tools.app: launches Alacritty + Emacsclient (waits for daemon)
  home.activation.createDevToolsApp = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      APP_DIR="$HOME/Applications/dev-tools.app"
      CONTENTS="$APP_DIR/Contents"

      mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

      cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>dev-tools</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>org.mgrbyte.dev-tools</string>
  <key>CFBundleName</key>
  <string>dev-tools</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
</dict>
</plist>
PLIST

      EMACSCLIENT_PATH="${pkgs.emacs}/bin/emacsclient"
      ALACRITTY_PATH="${pkgs.alacritty}/bin/alacritty"
      cat > "$CONTENTS/MacOS/dev-tools" << EXEC
#!/bin/bash
# Wait for Emacs daemon to be ready
until "$EMACSCLIENT_PATH" -e '(+ 1 1)' >/dev/null 2>&1; do
  sleep 0.5
done

# Launch Alacritty (if not already running)
if ! pgrep -x alacritty >/dev/null 2>&1; then
  open -a Alacritty
fi

# Open Emacsclient frame (open -a so it doesn't block)
open "$HOME/Applications/Emacsclient.app"

# Poll until Emacs has a window (up to 15 seconds), then tile
HS="/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs"
for i in \$(seq 1 30); do
  if "\$HS" -c 'for _, app in ipairs(hs.application.runningApplications()) do if app:name() == "emacs" and #app:allWindows() > 0 then return "ready" end end return "waiting"' 2>/dev/null | grep -q "ready"; then
    "\$HS" -c 'tileApps()' 2>/dev/null || true
    break
  fi
  sleep 0.5
done
EXEC
      chmod +x "$CONTENTS/MacOS/dev-tools"

      touch "$APP_DIR"
    ''
  );

  # Add apps to Dock
  home.activation.configureDock = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["createAppAliases" "createEmacsclientApp" "createDevToolsApp"] ''
      DOCKUTIL="${pkgs.dockutil}/bin/dockutil"
      CHANGED=0

      # Add Alacritty to dock from ~/Applications
      if ! "$DOCKUTIL" --find Alacritty >/dev/null 2>&1; then
        "$DOCKUTIL" --add "$HOME/Applications/Alacritty.app" --no-restart >/dev/null 2>&1 || true
        CHANGED=1
      fi

      # Add Emacsclient from ~/Applications (Emacs runs as daemon, so only need client)
      if ! "$DOCKUTIL" --find Emacsclient >/dev/null 2>&1; then
        "$DOCKUTIL" --add "$HOME/Applications/Emacsclient.app" --no-restart >/dev/null 2>&1 || true
        CHANGED=1
      fi

      # Restart dock only if we made changes
      if [[ $CHANGED -eq 1 ]]; then
        killall Dock 2>/dev/null || true
      fi
    ''
  );

  # Provide glibtool for vterm compilation (macOS expects glibtool, nix provides libtool)
  home.file.".local/bin/glibtool" = lib.mkIf isDarwin {
    executable = true;
    text = ''
      #!/bin/bash
      exec ${pkgs.libtool}/bin/libtool "$@"
    '';
  };
}
