{ config, pkgs, lib, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    # ./storage.nix
  ];

  modules.base.enable = true;
  modules.secrets.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Traefik logging
  services.traefik.staticConfigOptions.log.level = "DEBUG";
  
  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  modules.whoami.enable = true;
  networking.extraHosts = "";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

    # Ocis
  # modules.ocis = { 
  #   enable = false;
  #   hostName = "cloud.pingbit.de";
  #   dataDir = "/mnt/ocis";
  # };
  # Ocis remote user data 
  # NOTE: rclone does not support symlinks, which OCIS uses.
  modules.blobfuse.package = pkgs.unstable.blobfuse;
  modules.blobfuse.mounts."/mnt/ocis" = {
  #modules.blobfuse.mounts."${config.modules.ocis.dataDir}" = {
    configPath = config.age.secrets."blobfuse.yaml".path;
    container = "ocis";
    # uid = config.ids.uids.ocis;
    # gid = config.ids.gids.ocis;
  }; 

  # Immich remote data
  # TODO: maybe inject this into the immich systemd unit: https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#RequiresMountsFor=
  # modules.rclone.mounts."/mnt/photos" = {
  #   configPath = config.age.secrets.rclone-conf.path;
  #   remote = "azure-data:photos";
  #   uid = config.ids.uids.immich;
  #   gid = config.ids.gids.immich;
  #   mountOpts = [ "log-level=INFO" ];
  # };
  # Immich 
  modules.immich = {
    enable = false;
    hostName = "photos.pingbit.de";
    photosDir = "/mnt/photos";
  };


  ## Testing

  # systemd.mounts = [{
  #   enable = true;
  #   description = "blobfuse mount test";
  #   after = [ "network-online.target" ];
  #   requires = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   what = "${pkgs.unstable.blobfuse}/bin/azure-storage-fuse"; #"azure-storage-fuse";
  #   where = "/var/lib/ocis";
  #   type = "fuse3";
  #   mountConfig = {
  #     SloppyOptions = true;
  #   };
  #   options = "defaults,_netdev,allow_other,--config-file=/home/me/blob-ocis.yaml"; 
  # }]; 

  # systemd.automounts = [{
  #   enable = true;
  #   after = [ "network-online.target" ];
  #   before = [ "remote-fs.target" ];
  #   where = "/mnt/azblob";
  #   wantedBy = [ "multi-user.target" ];
  # }];
}
