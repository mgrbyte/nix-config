{ config, pkgs, lib, ... }:

let
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
  };
}
