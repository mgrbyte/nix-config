{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
           set -g @tmux_power_theme 'gold'
           set -g @tmux_power_time_format '%H:%M'
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

      # Emacs-style paste with prefix + C-y
      bind C-y paste-buffer

      # M-w in copy mode copies to system clipboard (like tmux-yank's y)
      bind -T copy-mode M-w send-keys -X copy-pipe-and-cancel "pbcopy"

      # Emacs-style scrolling: M-v page up, M-V (M-S-v) page down
      bind -n M-v copy-mode \; send-keys -X page-up
      bind -T copy-mode M-v send-keys -X page-up
      bind -T copy-mode M-V send-keys -X page-down

      # Copy entire visible pane to system clipboard
      bind M-c capture-pane -J \; save-buffer - \; delete-buffer \; run "tmux save-buffer - | pbcopy" \; display "Pane copied to clipboard"
    '';
  };
}
