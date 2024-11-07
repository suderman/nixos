{ config, ... }: let 

  automount = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
    "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
  ];
  nfs = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
    "_netdev"                      # mark as network device
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

  # Media network share
  # -------------------------------------------------------------------------
  fileSystems."/media" = {
    device = "lux:/media"; 
    fsType = "nfs";
    options = nfs;
  };

  # Additional SSD disk
  # -------------------------------------------------------------------------
  # Become root, insert disk and lookup the device name:
  # > sudo -s
  # > lsblk -f
  #
  # Assuming the disk is "nvme1n1", create the parition table and new partition:
  # > parted -s /dev/nvme1n1 mklabel gpt
  # > parted -s /dev/nvme1n1 mkpart data btrfs 1MiB 100%
  #
  # Verify it worked and take note of the partition name and UUID. 
  # Update the device attribute in the configuration below to match the UUID.
  # > lsblk -f
  #
  # Assuming the parition is "nvme1n1p1", format the partition as btrfs:
  # > mkfs.btrfs -fL data /dev/nvme1n1p1
  #
  # Create the mountpoint and mount the partition:
  # > mkdir -p /mnt/ssd
  # > mount /dev/nvme1n1p1 /mnt/ssd
  #
  # Create two subvolumes:
  # > btrfs subvolume create /mnt/ssd/snapshots
  # > btrfs subvolume create /mnt/ssd/data
  #
  fileSystems."/mnt/ssd" = {
    fsType = "btrfs"; 
    device = "/dev/disk/by-uuid/be48bf4a-6fc1-492c-bdf9-4e361c912e8c";
    options = btrfs ++ automount;
  };

  fileSystems."/data" = {
    device = "/mnt/ssd/data"; 
    options = bind ++ automount;
  };

  # Snapshots & backups
  services.btrbk = {
    enable = true;
    snapshots = {
      "/mnt/ssd".subvolume."data" = {};
    };
    backups = with config.networking; {
      "/nix".target."ssh://eve/backups/${hostName}" = {};
    };
  };
  
  # Additional filesystems in motd
  programs.rust-motd.settings.filesystems = {
    ssd = "/mnt/ssd";
  };

}
