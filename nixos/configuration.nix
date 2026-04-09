{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  services.timesyncd.enable = true;

  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Remap HHKB Studio Cmd key (Super) at the evdev level using keyd overload():
  # - tap Super alone  → Super (GNOME Activities launcher still works)
  # - hold Super + key → Alt+key (terminal sees Meta, no GNOME interception)
  services.keyd = {
    enable = true;
    keyboards = {
      hhkb-studio = {
        ids = [ "04fe:0016" ];
        settings = {
          main = {
            leftmeta = "overload(alt,leftmeta)";
            rightmeta = "overload(alt,rightmeta)";
          };
        };
      };
    };
  };

  users.users.mgrbyte = {
    isNormalUser = true;
    description = "Matthew Russell";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [];

  system.stateVersion = "25.11";
}