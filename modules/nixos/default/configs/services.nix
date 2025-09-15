{lib, ...}: {
  services.blocky.enable = lib.mkDefault true;
  services.earlyoom.enable = lib.mkDefault true;
  services.keyd.enable = lib.mkDefault true;
  services.tailscale.enable = lib.mkDefault true;
  services.traefik.enable = lib.mkDefault true;
  services.whoami.enable = lib.mkDefault true;
}
