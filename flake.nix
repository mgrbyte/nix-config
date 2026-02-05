{
  description = "Standalone Home Manager configuration for macOS and Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-config = {
      url = "github:mgrbyte/emacs.d";
      flake = false;
    };

    emacs-abyss-theme = {
      url = "github:mgrbyte/emacs-abyss-theme";
      flake = false;
    };

    nix-casks = {
      url = "github:atahanyorganci/nix-casks";
    };

    nix-colors = {
      url = "github:Misterio77/nix-colors";
    };

    home-manager-secrets = {
      url = "github:sudosubin/home-manager-secrets";
    };

    nix-secrets = {
      url = "git+ssh://git@github.com/mgrbyte/nix-secrets";
      flake = false;
    };

    hunspell-cy = {
      url = "github:techiaith/hunspell-cy";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, emacs-config, nix-casks, nix-colors, ... }@inputs:
    let
      user = "mtr21pqh";
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs emacs-config nix-colors;
          nix-secrets = inputs.nix-secrets;
          hunspell-cy = inputs.hunspell-cy;
          emacs-abyss-theme = inputs.emacs-abyss-theme;
        };
        modules = [
          nix-colors.homeManagerModules.default
          inputs.home-manager-secrets.homeManagerModules.home-manager-secrets
          ./home
        ];
      };
    in
    {
      # homeConfigurations."username" for each system
      # Use: home-manager switch --flake .#mtr21pqh
      homeConfigurations.${user} = mkHomeConfig "aarch64-darwin";

      # Also provide system-specific configs if needed
      # Use: home-manager switch --flake .#mtr21pqh-aarch64-darwin
      homeConfigurations."${user}-aarch64-darwin" = mkHomeConfig "aarch64-darwin";
      homeConfigurations."${user}-x86_64-darwin" = mkHomeConfig "x86_64-darwin";
      homeConfigurations."${user}-x86_64-linux" = mkHomeConfig "x86_64-linux";
      homeConfigurations."${user}-aarch64-linux" = mkHomeConfig "aarch64-linux";

      # Dev shell for working on this config
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ git ];
          };
        }
      );
    };
}
