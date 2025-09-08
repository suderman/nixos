{ lib, pkgs, perSystem, flake, inputs, ... }: let
  inherit (lib) mkDefault;
in {

  # Default to x86 linux
  nixpkgs.hostPlatform = mkDefault "x86_64-linux";

  # Accept agreements for unfree software
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  nixpkgs.overlays = [
  
     # Nix User Repositories 
    (final: prev: { nur = import inputs.nur { pkgs = final; nurpkgs = final; }; })

    # Modify existing packages
    (final: prev: let
      inherit (perSystem.self) enableWayland;
      rofi-wayland = { rofi-unwrapped = prev.rofi-wayland-unwrapped; };
    in {

      # Rofi plugins
      rofi-blezz = prev.rofi-blezz.override rofi-wayland;
      rofi-calc = prev.rofi-calc.override rofi-wayland;
      rofi-file-browser = prev.rofi-file-browser.override rofi-wayland;
      rofi-menugen = prev.rofi-menugen.override rofi-wayland;
      rofi-obsidian = prev.rofi-obsidian.override rofi-wayland;
      rofi-power-menu = prev.rofi-power-menu.override rofi-wayland;
      rofi-pulse-select = prev.rofi-pulse-select.override rofi-wayland;
      rofi-screenshot = prev.rofi-screenshot.override rofi-wayland;
      rofi-top = prev.rofi-top.override rofi-wayland;
      rofi-vpn = prev.rofi-vpn.override rofi-wayland;

      # These packages support Wayland but sometimes need to be persuaded
      digikam          = enableWayland { type = "qt"; package = prev.digikam; name = "digikam"; };
      dolphin          = enableWayland { type = "qt"; package = prev.dolphin; name = "dolphin"; };
      element-desktop  = enableWayland { type = "electron"; package = prev.element-desktop; name = "element-desktop"; };
      figma-linux      = enableWayland { type = "electron"; package = prev.figma-linux; name = "figma-linux"; };
      nextcloud-client = enableWayland { type = "qt"; package = prev.nextcloud-client; name = "nextcloud"; };
      # owncloud-client  = enableWayland { type = "qt"; package = prev.owncloud-client; name = "owncloud"; };
      plexamp          = enableWayland { type = "electron"; package = prev.plexamp; name = "plexamp"; };
      signal-desktop   = enableWayland { type = "electron"; package = prev.signal-desktop; name = "signal-desktop"; };
      # _1password-gui  = enableWayland { type = "electron"; package = prev._1password-gui; name = "1password"; };

      # Enable policies and import personal Certificate Authority
      firefox = prev.firefox.override {
        extraPolicies = {
          DontCheckDefaultBrowser = true;
          DisablePocket = true;
          DisableFirefoxStudies = true;
          Certificates = { ImportEnterpriseRoots = true; Install = [ flake.networking.ca ]; };
        };
      }; 

    }) 
  
  ];

}
