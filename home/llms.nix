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
in {
  # Claude Code MCP server configuration
  home.file.".mcp.json".text = builtins.toJSON mcpConfig;
}
