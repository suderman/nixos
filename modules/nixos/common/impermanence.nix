{ config, inputs, lib, ... }: let

  cfg = config.state;
  inherit (lib) mkBefore mkOption types;

in {

  # Import impermanence module
  imports = [ inputs.impermanence.nixosModule ];

  # Extra options
  options.state = {

    stateDir = mkOption { 
      type = types.str;
      default = "/mnt/main/state";
    };

    # Files relative to / root
    files = mkOption {
      description = "System files to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Directories relative to / root
    dirs = mkOption {
      description = "System directories to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

  };

  config = {

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${cfg.stateDir}" = {
        hideMounts = true;

        # System files
        files = cfg.files;

        # System directories
        directories = [
          # "/etc/nixos"
          "/etc/NetworkManager/system-connections"
          # "/var/lib"  
          "/var/log"  
          # "/home"  
        ] ++ cfg.dirs;

      };
    };

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Maintain machine identification
    environment.etc."machine-id".source = "${cfg.stateDir}/etc/machine-id";

    # Maintain auto-generated ssh host rsa keys
    services.openssh.hostKeys = [{
      path = "${cfg.stateDir}/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }];

    # # Script to wipe the root subvolume at boot
    # boot.initrd.postDeviceCommands = mkBefore ''
    #   # Mount btrfs disk to /mnt
    #   mkdir -p /mnt
    #   mount /dev/disk/by-label/nix /mnt
    #
    #   # Delete all of root's subvolumes
    #   btrfs subvolume list -o /mnt/root |
    #   cut -f9 -d' ' |
    #   while read subvolume; do
    #     btrfs subvolume delete "/mnt/$subvolume"
    #   done
    #
    #   # Delete root itself
    #   btrfs subvolume delete /mnt/root
    #
    #   # Restore root from blank snapshot
    #   btrfs subvolume snapshot /mnt/snapshots/root /mnt/root
    #
    #   # Clean up
    #   umount /mnt
    # '';

  };

}
