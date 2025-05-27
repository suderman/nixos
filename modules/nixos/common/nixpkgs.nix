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
      digikam          = enableWayland { type = "qt"; pkg = prev.digikam; bin = "digikam"; };
      dolphin          = enableWayland { type = "qt"; pkg = prev.dolphin; bin = "dolphin"; };
      element-desktop  = enableWayland { type = "electron"; pkg = prev.element-desktop; bin = "element-desktop"; };
      figma-linux      = enableWayland { type = "electron"; pkg = prev.figma-linux; bin = "figma-linux"; };
      nextcloud-client = enableWayland { type = "qt"; pkg = prev.nextcloud-client; bin = "nextcloud"; };
      # owncloud-client  = enableWayland { type = "qt"; pkg = prev.owncloud-client; bin = "owncloud"; };
      plexamp          = enableWayland { type = "electron"; pkg = prev.plexamp; bin = "plexamp"; };
      signal-desktop   = enableWayland { type = "electron"; pkg = prev.signal-desktop; bin = "signal-desktop"; };
      # _1password-gui  = enableWayland { type = "electron"; pkg = prev._1password-gui; bin = "1password"; };

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
