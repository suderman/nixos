# desktop.enable = true;
{lib, ...}: {
  options.desktop = lib.mkEnableOption "desktop";
}
