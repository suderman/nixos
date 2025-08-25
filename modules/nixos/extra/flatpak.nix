# services.flatpak.enable = true;
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services.flatpak;
  inherit (lib) mkIf mkOption types;
in {
  # https://github.com/gmodena/nix-flatpak/blob/main/modules/nixos.nix
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

  # options shared with home-manager module
  options.services.flatpak = {
    # Stable and beta packages
    apps = mkOption {
      type = with types; (listOf str);
      default = [];
    };
    beta = mkOption {
      type = with types; (listOf str);
      default = [];
    };

    # Combined packages
    all = mkOption {
      type = with types; (listOf str);
      readOnly = true;
      default = cfg.apps ++ cfg.beta;
    };
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      # allow imperative system flatpaks
      uninstallUnmanaged = false;

      # Weekly updates
      update.auto.enable = true;

      # Stable and beta repos
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "flathub-beta";
          location = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];

      # Combine lists into one for services.flatpak.packages
      packages =
        (
          map (appId: {
            inherit appId;
            origin = "flathub";
          })
          cfg.apps
        )
        ++ (
          map (appId: {
            inherit appId;
            origin = "flathub-beta";
          })
          cfg.beta
        );
    };

    # portal required for flatpak
    xdg.portal = {
      enable = true;
      config.common.default = "*"; # "gtk"
      extraPortals = [pkgs.xdg-desktop-portal-gtk]; # or xdg-desktop-portal-kde
    };

    # browse (and try) flatpaks via Gnome Software
    environment.systemPackages = with pkgs; [gnome-software];

    # Persist data
    impermanence.scratch.directories = ["/var/lib/flatpak"];
  };
}
