# base.enable = true;
{ config, lib, ... }: with lib; {

  config = mkIf config.base.enable {

    # Skip password for sudo
    security.sudo.wheelNeedsPassword = false;

    # Increase open file limit for sudoers
    security.pam.loginLimits = [
      { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
      { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
    ];

  };

}
