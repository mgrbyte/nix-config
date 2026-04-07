{ config, pkgs, lib, ... }:

let
  copy = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
  paste = if pkgs.stdenv.isDarwin then "pbpaste" else "wl-paste";
in {
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          # Ensure Nix bash 5.x is used by plugin scripts (macOS ships bash 3.2
          # which doesn't support associative arrays needed by tokyo-night-tmux)
          set-environment -g PATH "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
          set -g @tokyo-night-tmux_theme 'night'
          set -g @tokyo-night-tmux_date_format 'DMY'
          set -g @tokyo-night-tmux_time_format '24H'
          set -g @tokyo-night-tmux_show_datetime 1
          set -g @tokyo-night-tmux_show_path 1
          set -g @tokyo-night-tmux_path_format 'relative'
          set -g @tokyo-night-tmux_show_music 1
          set -g @tokyo-night-tmux_show_battery_widget 1
          set -g @tokyo-night-tmux_show_hostname 1
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-t";
    keyMode = "emacs";
    mouse = true;
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Scroll up enters copy mode automatically; prevents escape sequences leaking to shell
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"

      # M-w in copy mode copies to system clipboard (like tmux-yank's y)
      bind -T copy-mode M-w send-keys -X copy-pipe-and-cancel "${copy}"

      # Emacs-style scrolling: M-v page up, M-V (M-S-v) page down
      bind -n M-v copy-mode \; send-keys -X page-up
      bind -T copy-mode M-v send-keys -X page-up
      bind -T copy-mode M-V send-keys -X page-down

      # Ctrl-Shift-v pastes from system clipboard
      bind -n C-S-v run "${paste} | tmux load-buffer - && tmux paste-buffer"

      # Copy entire visible pane to system clipboard
      bind M-c capture-pane -J \; save-buffer - \; delete-buffer \; run "tmux save-buffer - | ${copy}" \; display "Pane copied to clipboard"
    '';
  };
}
