# services.keyd.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.services.keyd;
  inherit (lib) mkIf mkForce mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) extraGroups;

in {

  options.services.keyd = {
    # enable = mkEnableOption "keyd"; 
    quirks = mkEnableOption "quirks"; 
    internalKeyboards = mkOption {
      type = types.anything;
      default = {
        framework = import ./keyboards/framework.nix;
        t480s = import ./keyboards/t480s.nix;
      };
    };
    externalKeyboards = mkOption {
      type = types.anything;
      default = {
        apple = import ./keyboards/apple.nix;
        g600  = import ./keyboards/g600.nix;
        hhkb  = import ./keyboards/hhkb.nix;
        k811  = import ./keyboards/k811.nix;
        rii   = import ./keyboards/rii.nix;
        w3    = import ./keyboards/w3.nix;
      };
    };
    keyboard = mkOption {
      type = types.anything;
      default = {
        ids = [ "0001:0001" ];
        settings = {};
      };
    };
  };

  config = mkIf cfg.enable {

    # Install keyd package
    environment.systemPackages = [ pkgs.keyd ];

    # Enable systemd service with keyboard configuration
    services.keyd = {
      keyboards = cfg.externalKeyboards // { 
        default = cfg.keyboard; 
      };
    };

    # https://github.com/NixOS/nixpkgs/issues/290161
    systemd.services.keyd.serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];

    # Add quirks to make touchpad's "disable-while-typing" work properly
    environment.etc."libinput/local-overrides.quirks" = mkIf cfg.quirks { source = ./local-overrides.quirks; };

    # Create keyd group
    users.groups.keyd = {};

    # Add flake's users to the keyd (and ydotool) group
    users.users = extraGroups this.users [ "keyd" "ydotool" ];

    # Also enable ydotool 
    programs.ydotool.enable = true;

    # Monitor keyd events 
    systemd.services.keyd-monitor = {
      description = "Keyd monitor";
      after = [ "keyd.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils keyd ];
      script = builtins.readFile ./monitor.sh;
    };

    # Ensure read permissions for mouse-button click
    file."/run/keyd/button" = { type = "file"; mode = 644; user = "root"; group = "keyd"; };

  };

}
