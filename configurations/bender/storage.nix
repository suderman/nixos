{ config, pkgs, ... }: let 

  automount = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
    "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
  ];
  btrfs = [ 
    "compress=zstd"                # enable zstd compression
    "space_cache=v2"               # track available free space on filesystem
    "discard=async"                # free up deleted space in the background
    "noatime"                      # disables access time updates on files
  ]; 
  bind = [ "bind" ]; 

in {

  # Btrfs mount options
  fileSystems."/".options = btrfs;
  fileSystems."/nix".options = btrfs;

  # Blobfuse mounts
  # Workarounds
  modules.blobfuse.package = pkgs.unstable.blobfuse;
  age.secrets.blobfuse-yaml.name = "blobfuse.yaml"; # blobfuse inists on a ".yaml extension. This messes up secrets handling with "nixos secrets", as dots indicate a hierarchy level in nix.

  # TODO: wrap this in a module/overlay/whatever is a smooth way to integrate it with existing modules
  # TODO: make mountpoint immutable so it is not accidently written

  systemd.services.docker-ocis.unitConfig = {
    RequiresMountsFor = "${config.modules.ocis.dataDir}/storage";
  };
  modules.blobfuse.mounts."${config.modules.ocis.dataDir}/storage" = {
    configPath = config.age.secrets."blobfuse-yaml".path;
    container = "ocis";
    uid = config.ids.uids.ocis;
    gid = config.ids.gids.ocis;
  }; 

  systemd.services.immich.unitConfig = {
    RequiresMountsFor = config.modules.immich.dataDir;
  };
  modules.blobfuse.mounts."${config.modules.immich.dataDir}" = {
    configPath = config.age.secrets."blobfuse-yaml".path;
    container = "photos";
    uid = config.ids.uids.immich;
    gid = config.ids.gids.immich;
  }; 

  ## Backup

  modules.restic.enable = true;
}