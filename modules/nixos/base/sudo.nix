{ config, lib, ... }: 

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Does sudo need a password?
    security.sudo.wheelNeedsPassword = true;

    # If so, how long before asking again?
    security.sudo.extraConfig = lib.mkAfter ''
      Defaults timestamp_timeout=60
      Defaults lecture=never
    '';

    # Increase open file limit for sudoers
    security.pam.loginLimits = [
      { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
      { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
    ];

  };

}
