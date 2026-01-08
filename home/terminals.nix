{ config, pkgs, lib, ... }:

let
  # Helper to convert hex color to iTerm2 plist format (RGB 0.0-1.0)
  hexToIterm = hex: let
    r = builtins.substring 0 2 hex;
    g = builtins.substring 2 2 hex;
    b = builtins.substring 4 2 hex;
    hexToDec = h: let
      chars = lib.stringToCharacters h;
      hexDigit = c:
        if c == "a" || c == "A" then 10
        else if c == "b" || c == "B" then 11
        else if c == "c" || c == "C" then 12
        else if c == "d" || c == "D" then 13
        else if c == "e" || c == "E" then 14
        else if c == "f" || c == "F" then 15
        else lib.strings.toInt c;
    in (hexDigit (builtins.elemAt chars 0)) * 16 + (hexDigit (builtins.elemAt chars 1));
    toFloat = n: "${toString n}.0";
    normalize = n: "${toString (n / 255.0)}";
  in {
    red = normalize (hexToDec r);
    green = normalize (hexToDec g);
    blue = normalize (hexToDec b);
  };

  # Generate an iTerm2 color entry
  itermColorEntry = name: hex: let
    c = hexToIterm hex;
  in ''
    <key>${name}</key>
    <dict>
      <key>Alpha Component</key>
      <real>1</real>
      <key>Blue Component</key>
      <real>${c.blue}</real>
      <key>Color Space</key>
      <string>sRGB</string>
      <key>Green Component</key>
      <real>${c.green}</real>
      <key>Red Component</key>
      <real>${c.red}</real>
    </dict>
  '';

  p = config.colorScheme.palette;
in {
  home.file = {
    # Alacritty terminal config with nix-colors
    ".config/alacritty/alacritty.toml".text = ''
      # Window configuration
      [window]
      dimensions = { columns = 207, lines = 58 }
      padding = { x = 12, y = 12 }
      decorations = "Full"
      opacity = 1.0
      option_as_alt = "Both"
      startup_mode = "Windowed"

      # Font configuration
      [font]
      size = 14.0

      [font.normal]
      family = "Hack Nerd Font"
      style = "Regular"

      [font.bold]
      family = "Hack Nerd Font"
      style = "Bold"

      [font.italic]
      family = "Hack Nerd Font"
      style = "Italic"

      # Colors from nix-colors (${config.colorScheme.slug})
      [colors.primary]
      background = "#${p.base00}"
      foreground = "#${p.base05}"

      [colors.cursor]
      text = "#${p.base00}"
      cursor = "#${p.base05}"

      [colors.selection]
      text = "#${p.base05}"
      background = "#${p.base02}"

      [colors.normal]
      black = "#${p.base00}"
      red = "#${p.base08}"
      green = "#${p.base0B}"
      yellow = "#${p.base0A}"
      blue = "#${p.base0D}"
      magenta = "#${p.base0E}"
      cyan = "#${p.base0C}"
      white = "#${p.base05}"

      [colors.bright]
      black = "#${p.base03}"
      red = "#${p.base08}"
      green = "#${p.base0B}"
      yellow = "#${p.base0A}"
      blue = "#${p.base0D}"
      magenta = "#${p.base0E}"
      cyan = "#${p.base0C}"
      white = "#${p.base07}"

      # Scrolling
      [scrolling]
      history = 10000
      multiplier = 3

      # Selection
      [selection]
      save_to_clipboard = true
    '';

    # iTerm2 color scheme from nix-colors (dracula)
    # Import in iTerm2: Preferences → Profiles → Colors → Color Presets → Import
    ".config/iterm2/nix-colors.itermcolors".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        ${itermColorEntry "Ansi 0 Color" p.base00}
        ${itermColorEntry "Ansi 1 Color" p.base08}
        ${itermColorEntry "Ansi 2 Color" p.base0B}
        ${itermColorEntry "Ansi 3 Color" p.base0A}
        ${itermColorEntry "Ansi 4 Color" p.base0D}
        ${itermColorEntry "Ansi 5 Color" p.base0E}
        ${itermColorEntry "Ansi 6 Color" p.base0C}
        ${itermColorEntry "Ansi 7 Color" p.base05}
        ${itermColorEntry "Ansi 8 Color" p.base03}
        ${itermColorEntry "Ansi 9 Color" p.base08}
        ${itermColorEntry "Ansi 10 Color" p.base0B}
        ${itermColorEntry "Ansi 11 Color" p.base0A}
        ${itermColorEntry "Ansi 12 Color" p.base0D}
        ${itermColorEntry "Ansi 13 Color" p.base0E}
        ${itermColorEntry "Ansi 14 Color" p.base0C}
        ${itermColorEntry "Ansi 15 Color" p.base07}
        ${itermColorEntry "Background Color" p.base00}
        ${itermColorEntry "Badge Color" p.base0E}
        ${itermColorEntry "Bold Color" p.base06}
        ${itermColorEntry "Cursor Color" p.base05}
        ${itermColorEntry "Cursor Guide Color" p.base02}
        ${itermColorEntry "Cursor Text Color" p.base00}
        ${itermColorEntry "Foreground Color" p.base05}
        ${itermColorEntry "Link Color" p.base0D}
        ${itermColorEntry "Selected Text Color" p.base05}
        ${itermColorEntry "Selection Color" p.base02}
      </dict>
      </plist>
    '';
  };
}
