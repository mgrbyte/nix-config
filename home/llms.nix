{ config, pkgs, lib, homeDir, ... }:

let
  mcpConfig = {
    mcpServers = {
      serena = {
        command = "uvx";
        args = [ "--from" "git+https://github.com/oraios/serena" "serena" "start-mcp-server" ];
      };
      emacs = {
        command = "socat";
        args = [ "-" "UNIX-CONNECT:${homeDir}/.emacs.d/emacs-mcp-server.sock" ];
      };
    };
  };

  # Claude Code config directories
  claudePublicDir = "${homeDir}/github/mgrbyte/nix-config/home/claude";
  claudePrivateDir = "${homeDir}/github/mgrbyte/vibing/claude/config";

  # Helper: create an out-of-store symlink so files remain editable
  mkClaudeLink = dir: path: {
    name = ".claude/${path}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${dir}/${path}";
    };
  };

  # Public files (nix-config repo)
  publicRules = map (mkClaudeLink claudePublicDir) [
    "rules/general.md"
    "rules/git.md"
    "rules/handover-memories.md"
    "rules/emacs-packages.md"
    "rules/emacs.md"
    "rules/docker.md"
    "rules/javascript.md"
    "rules/markdown.md"
    "rules/python-scripts.md"
    "rules/python.md"
    "rules/research-first.md"
    "rules/testing-patterns.md"
    "rules/README.md"
  ];

  publicHooks = map (mkClaudeLink claudePublicDir) [
    "hooks/hooks.json"
    "hooks/posttooluse-format.sh"
    "hooks/pretooluse-guard.py"
    "hooks/stop-hook-check.py"
    "hooks/README.md"
  ];

  publicOther = map (mkClaudeLink claudePublicDir) [
    "output-styles/python-pair-programming-buddy.md"
  ];

  # Private files (vibing repo)
  privateFiles = map (mkClaudeLink claudePrivateDir) [
    "CLAUDE.md"
    "settings.json"
    "rules/org.md"
    "rules/remote-dev-workflow.md"
  ];

in {
  # Claude Code MCP server configuration
  home.file = builtins.listToAttrs (
    publicRules ++ publicHooks ++ publicOther ++ privateFiles
  ) // {
    ".mcp.json".text = builtins.toJSON mcpConfig;
  };
}
