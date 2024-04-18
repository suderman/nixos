# modules.keyd.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.keyd;
  inherit (lib) mkIf mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) extraGroups;

in {

  options.modules.keyd = {
    enable = mkEnableOption "keyd"; 
    quirks = mkEnableOption "quirks"; 
    settings = mkOption {
      type = types.path;
      default = ./default.conf;
    };
    configs = mkOption {
      type = types.anything;
      default = {
        framework = ./framework.conf;
      };
    };
  };

  config = mkIf cfg.enable {

    # Install keyd package
    environment.systemPackages = [ pkgs.keyd ];

    users = {

      # Create keyd group
      groups.keyd.name = "keyd";

      # Add users to the keyd group
      users = extraGroups this.users [ "keyd" ];

    };

    # Create service for daemon process
    systemd.services.keyd = {
      description = "key remapping daemon";
      requires = [ "local-fs.target" ];
      after = [ "local-fs.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.keyd}/bin/keyd";
      };
      restartIfChanged = false;
    };

    # Configuration for keyd
    environment.etc."keyd/default.conf".source = cfg.settings;
    environment.etc."keyd/apple.conf".source = ./apple.conf;
    environment.etc."keyd/g600.conf".source = ./g600.conf;
    environment.etc."keyd/hhkb.conf".source = ./hhkb.conf;
    environment.etc."keyd/k811.conf".source = ./k811.conf;

    # Add quirks to make touchpad's "disable-while-typing" work properly
    environment.etc."libinput/local-overrides.quirks" = mkIf cfg.quirks { source = ./local-overrides.quirks; };

  };

}
