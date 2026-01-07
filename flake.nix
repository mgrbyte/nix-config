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

    nix-casks = {
      url = "github:atahanyorganci/nix-casks";
    };
  };

  outputs = { nixpkgs, home-manager, emacs-config, nix-casks, ... }@inputs:
    let
      user = "mtr21pqh";
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs emacs-config; };
        modules = [ ./home.nix ];
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
