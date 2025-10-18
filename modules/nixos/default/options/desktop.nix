# This option is set true by nixosModules.desktops.default
# desktop.enable = true;
#
# Can be used elsewhere to set config exclusively on desktop
# programs = config.desktop { foo.bar = []; };
{lib, ...}: {
  options.desktop = lib.mkOption {
    type = lib.types.anything;
  };
  config.desktop = {
    enable = lib.mkDefault false;
    __functor = self: attrs:
      if self.enable
      then attrs
      else {};
  };
}
