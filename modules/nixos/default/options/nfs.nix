{
  config,
  pkgs,
  ...
}: let
  cfg = config.services.nfs.server;
in {
  # Enable nfs
  services.rpcbind.enable = true;
  environment.systemPackages = [pkgs.nfs-utils];

  # Fixed nfs ports
  services.nfs.server = {
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  # Open firewall if nfs server enabled
  networking.firewall =
    if cfg.enable != true
    then {}
    else {
      allowedTCPPorts = [111 2049 4000 4001 4002 20048];
      allowedUDPPorts = [111 2049 4000 4001 4002 20048];
    };

  # # Ensure /media exists
  # systemd.services.createMediaDir = {
  #   after = [ "local-fs.target" ];  # Ensure this runs after the root fs is mounted
  #   before = [ "local-fs-pre.target" ];  # Ensure this runs before other filesystems are mounted
  #   wantedBy = [ "multi-user.target" ];  # Run as part of multi-user (standard boot)
  #   script = "mkdir -p /media";
  # };
}
