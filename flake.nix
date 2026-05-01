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

    emacs-tokyo-theme = {
      url = "github:bbatsov/emacs-tokyo-themes";
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

  };

  outputs = { nixpkgs, home-manager, emacs-config, nix-casks, nix-colors, ... }@inputs:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      mkHomeConfig = { system, user, nixUserChroot ? false }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs emacs-config nix-colors user nixUserChroot;
          nix-secrets = inputs.nix-secrets;
          emacs-abyss-theme = inputs.emacs-abyss-theme;
          emacs-tokyo-theme = inputs.emacs-tokyo-theme;
        };
        modules = [
          nix-colors.homeManagerModules.default
          inputs.home-manager-secrets.homeManagerModules.home-manager-secrets
          ./home
        ];
      };
    in
    {
      # homeConfigurations for mtr21pqh (work macOS)
      # Use: home-manager switch --flake .#mtr21pqh
      homeConfigurations."mtr21pqh" = mkHomeConfig { system = "aarch64-darwin"; user = "mtr21pqh"; };
      homeConfigurations."mtr21pqh-aarch64-darwin" = mkHomeConfig { system = "aarch64-darwin"; user = "mtr21pqh"; };
      homeConfigurations."mtr21pqh-x86_64-darwin" = mkHomeConfig { system = "x86_64-darwin"; user = "mtr21pqh"; };
      homeConfigurations."mtr21pqh-x86_64-linux" = mkHomeConfig { system = "x86_64-linux"; user = "mtr21pqh"; };
      homeConfigurations."mtr21pqh-chroot-x86_64-linux" = mkHomeConfig { system = "x86_64-linux"; user = "mtr21pqh"; nixUserChroot = true; };
      homeConfigurations."mtr21pqh-aarch64-linux" = mkHomeConfig { system = "aarch64-linux"; user = "mtr21pqh"; };

      # homeConfigurations for mgrbyte (personal NixOS)
      # Use: home-manager switch --flake .#mgrbyte
      homeConfigurations."mgrbyte" = mkHomeConfig { system = "x86_64-linux"; user = "mgrbyte"; };
      homeConfigurations."mgrbyte-x86_64-linux" = mkHomeConfig { system = "x86_64-linux"; user = "mgrbyte"; };
      homeConfigurations."mgrbyte-aarch64-linux" = mkHomeConfig { system = "aarch64-linux"; user = "mgrbyte"; };

      # NixOS system configuration for mgrbyte's personal Linux machine
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./nixos/configuration.nix ];
      };

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
