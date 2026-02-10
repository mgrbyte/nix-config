{ config, pkgs, lib, homeDir, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Disable copyApps - requires App Management permission which is problematic
  # Living with shortcut arrow on dock icons instead
  targets.darwin.copyApps.enable = false;

  # Install Karabiner-Elements via Homebrew (needs system drivers)
  home.activation.installKarabiner = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Karabiner needs system drivers that only the official installer provides
      BREW="/opt/homebrew/bin/brew"
      if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "/Applications/Karabiner-Elements.app/Contents/Info.plist" 2>/dev/null | grep -q "org.pqrs.Karabiner-Elements"; then
        if [[ -x "$BREW" ]]; then
          echo "Installing Karabiner-Elements via Homebrew..."
          "$BREW" install --cask karabiner-elements || true
        else
          echo "WARNING: Karabiner-Elements requires Homebrew installation."
          echo "Install Homebrew first, then run: brew install --cask karabiner-elements"
        fi
      fi
    ''
  );

  # Note: Karabiner config is NOT managed by nix (triggers keyboard dialog on each change)
  # Config lives at ~/.config/karabiner/karabiner.json - edit manually if needed
  # Current mappings: Cmd+f/b/d/u/l/y/./,/</> -> Meta equivalents in terminals

  # Create Spotlight-indexable aliases for nix apps in ~/Applications
  # Using ~/Applications avoids JAMF/IT restrictions on /Applications
  home.activation.createAppAliases = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/Applications"
      for app in Alacritty Emacs; do
        if [[ -e "$HOME/.nix-profile/Applications/$app.app" ]]; then
          # Remove ALL existing aliases/files matching this app name
          # Use find to handle spaces in filenames and numbered variants
          find "$HOME/Applications" -maxdepth 1 -name "$app.app*" -exec rm -rf {} + 2>/dev/null || true
          # Create new Finder alias (Finder may add " alias" suffix)
          /usr/bin/osascript -e "tell application \"Finder\" to make alias file to POSIX file \"$HOME/.nix-profile/Applications/$app.app\" at POSIX file \"$HOME/Applications\"" >/dev/null 2>&1 || true
          # Rename if Finder added " alias" suffix
          if [[ -e "$HOME/Applications/$app.app alias" ]]; then
            mv "$HOME/Applications/$app.app alias" "$HOME/Applications/$app.app"
          fi
        fi
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

  # Add apps to Dock
  home.activation.configureDock = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["createAppAliases" "createEmacsclientApp"] ''
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
