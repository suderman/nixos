{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.glib];
  services.gvfs = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.gvfs;
  };
}
