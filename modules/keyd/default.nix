# modules.keyd.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.keyd;
  inherit (lib) mkIf mkForce mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) extraGroups;

in {

  options.modules.keyd = {
    enable = mkEnableOption "keyd"; 
    quirks = mkEnableOption "quirks"; 
    keyboards = mkOption {
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
      enable = true;
      keyboards = cfg.externalKeyboards // { 
        default = cfg.keyboard; 
      };
    };

    # https://github.com/NixOS/nixpkgs/issues/290161
    systemd.services.keyd.serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];

    # Create keyd group
    users.groups.keyd = {};

    # Add flake's users to the keyd group
    users.users = extraGroups this.users [ "keyd" ];

    # Add quirks to make touchpad's "disable-while-typing" work properly
    environment.etc."libinput/local-overrides.quirks" = mkIf cfg.quirks { source = ./local-overrides.quirks; };

  };

}
