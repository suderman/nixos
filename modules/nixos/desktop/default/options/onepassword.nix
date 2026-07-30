{
  config,
  lib,
  ...
}: let
  users = config.home-manager.users or {};
  owners = builtins.attrNames (lib.filterAttrs (_: user: user.programs.onepassword.enable or false) users);
in {
  config = lib.mkIf (owners != []) {
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = owners;
    };
  };
}
