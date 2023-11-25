{ config, pkgs, lib, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    # ./storage.nix
  ];
  
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
  modules.ocis = { 
    enable = true;
    hostName = "cloud.pingbit.de";
    # dataDir = "/mnt/ocis";
  };

  # Ocis remote user data 
  # NOTE: rclone does not support symlinks, which OCIS uses.
  modules.blobfuse.package = pkgs.unstable.blobfuse;
  
  # Workarounds
  age.secrets.blobfuse-yaml.name = "blobfuse.yaml"; # blobfuse inists on a ".yaml extension. This messes up secrets handling with "nixos secrets", as dots indicate a hierarchy level in nix.
  # TODO: maybe also inject RequiresMountsFor into systemd unit: https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#RequiresMountsFor=
  systemd.services.docker-ocis.bindsTo = [ "var-lib-ocis-storage.mount" ]; # create a dependency that also kills the service, if the mount is gone
  # TODO: make mountpoint immutable so it is not accidently written

  # TODO: wrap this in a module/overlay/whatever is a smooth way to integrate it with existing modules
  modules.blobfuse.mounts."${config.modules.ocis.dataDir}/storage" = {
  #modules.blobfuse.mounts."/mnt/ocis" = {
  #modules.blobfuse.mounts."${config.modules.ocis.dataDir}" = {
    configPath = config.age.secrets."blobfuse-yaml".path;
    container = "ocis";
    # mountOpts = [ "--log-level=LOG_DEBUG" ];
    uid = config.ids.uids.ocis;
    gid = config.ids.gids.ocis;
  }; 

  # Immich remote data
  # modules.rclone.mounts."/mnt/photos" = {
  #   configPath = config.age.secrets.rclone-conf.path;
  #   remote = "azure-data:photos";
  #   uid = config.ids.uids.immich;
  #   gid = config.ids.gids.immich;
  #   mountOpts = [ "log-level=INFO" ];
  # };

  systemd.services.immich.unitConfig = {
    RequiresMountsFor = config.modules.immich.dataDir;
  };
  modules.blobfuse.mounts."${config.modules.immich.dataDir}" = {
  #modules.blobfuse.mounts."/mnt/ocis" = {
  #modules.blobfuse.mounts."${config.modules.ocis.dataDir}" = {
    configPath = config.age.secrets."blobfuse-yaml".path;
    container = "photos";
    uid = config.ids.uids.immich;
    gid = config.ids.gids.immich;
  }; 
  # Immich 
  modules.immich = {
    enable = true;
    hostName = "photos.pingbit.de";
    dataDir = "/mnt/photos";
  };

  modules.silverbullet.enable = true;
  modules.silverbullet.hostName = "wiki.pingbit.de";
  
  modules.netdata.enable = true;

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

# Ideas / todos:
# use https://github.com/berberman/nvfetcher to update docker images