# services.keyd.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.services.keyd;
  inherit (lib) mkIf mkOption types recursiveUpdate;
  inherit (lib.options) mkEnableOption;
  getKeyboard = path: recursiveUpdate (import ./keyboards/all.nix) (import path);
in {
  options.services.keyd = {
    quirks = mkEnableOption "quirks";
    internalKeyboards = mkOption {
      type = types.anything;
      default = {
        framework = getKeyboard ./keyboards/framework.nix;
        t480s = getKeyboard ./keyboards/t480s.nix;
      };
    };
    externalKeyboards = mkOption {
      type = types.anything;
      default = {
        apple = getKeyboard ./keyboards/apple.nix;
        g600 = getKeyboard ./keyboards/g600.nix;
        hhkb = getKeyboard ./keyboards/hhkb.nix;
        k811 = getKeyboard ./keyboards/k811.nix;
        rii = getKeyboard ./keyboards/rii.nix;
        w3 = getKeyboard ./keyboards/w3.nix;
      };
    };
    keyboard = mkOption {
      type = types.anything;
      default = {
        ids = ["0001:0001"];
        settings = {};
      };
    };
  };

  config = mkIf cfg.enable {
    # Install keyd package
    environment.systemPackages = [pkgs.keyd];

    # Enable systemd service with keyboard configuration
    services.keyd = {
      keyboards =
        cfg.externalKeyboards
        // {
          default = cfg.keyboard;
        };
    };

    # https://github.com/NixOS/nixpkgs/issues/290161
    systemd.services.keyd.serviceConfig.CapabilityBoundingSet = ["CAP_SETGID"];

    # Add quirks to make touchpad's "disable-while-typing" work properly
    environment.etc."libinput/local-overrides.quirks" = mkIf cfg.quirks {source = ./local-overrides.quirks;};

    # Create keyd group
    users.groups.keyd = {};

    # Add config's users to the keyd, ydotool groups
    users.users = flake.lib.extraGroups config ["keyd" "ydotool"];

    # Also enable ydotool
    programs.ydotool.enable = true;

    # Monitor keyd events
    systemd.services.keyd-monitor = {
      description = "Keyd monitor";
      after = ["keyd.service"];
      wantedBy = ["multi-user.target"];
      path = with pkgs; [coreutils keyd];
      script = builtins.readFile ./monitor.sh;
    };

    # Ensure read permissions for mouse-button click
    tmpfiles.files = [
      {
        target = "/run/keyd/button";
        mode = 644;
        user = "root";
        group = "keyd";
      }
    ];
  };
}
