# services.keyd.enable = true;
{ config, lib, pkgs, user, ... }: 

let 

  cfg = config.services.keyd;
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

in {

  options = {
    services.keyd.enable = mkEnableOption "keyd"; 
  };

  config = mkIf cfg.enable {

    # Install keyd package
    environment.systemPackages = [ pkgs.keyd ];

    # Create keyd group
    users.groups.keyd.name = "keyd";

    # Add user to the keyd group
    users.users."${user}".extraGroups = [ "keyd" ]; 

    # Create service for daemon process
    systemd.services.keyd = {
      description = "key remapping daemon";
      requires = [ "local-fs.target" ];
      after = [ "local-fs.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.keyd}/bin/keyd";
      };
    };

    # Add quirks to make touchpad's "disable-while-typing" work properly
    environment.etc."libinput/local-overrides.quirks".source = ./local-overrides.quirks;

    # Configuration for keyd
    environment.etc."keyd/default.conf".source = ./default.conf;

  };

}
