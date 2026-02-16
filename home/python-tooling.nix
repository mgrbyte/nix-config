{ config, pkgs, lib, homeDir, ... }:

{
  # Mypy wrapper for flycheck (runs mypy via uv in project context)
  # Finds project root and runs mypy with correct config for namespace packages
  home.file.".local/bin/uv-mypy" = {
    text = ''
      #!/bin/bash
      set -e

      # Find project root by looking for mypy.ini or pyproject.toml
      find_project_root() {
        local dir="$1"
        while [[ "$dir" != "/" ]]; do
          if [[ -f "$dir/mypy.ini" ]] || [[ -f "$dir/pyproject.toml" ]]; then
            echo "$dir"
            return 0
          fi
          dir="$(dirname "$dir")"
        done
        return 1
      }

      # Get the file being checked (last argument)
      file="''${!#}"

      if [[ -f "$file" ]]; then
        file="$(realpath "$file")"
        project_root="$(find_project_root "$(dirname "$file")")" || project_root=""

        if [[ -n "$project_root" ]]; then
          cd "$project_root"
          # Make file path relative to project root
          rel_file="''${file#$project_root/}"
          # Run mypy from project root
          exec uv run mypy "$rel_file"
        fi
      fi

      # Fallback: run mypy as-is
      exec uv run mypy "$@"
    '';
    executable = true;
  };
}
