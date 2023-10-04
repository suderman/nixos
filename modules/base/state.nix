# Add directories or files to persist
# modules.base.dirs = [ "/var/lib/systemd" ];
# modules.base.files = [ "/etc/machine-id" ];
#
{ config, lib, inputs, ... }: 

let 

  cfg = config.modules.base;
  dir = "/nix/state";
  inherit (lib) mkOption mkBefore mkIf types;

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  # Persist in /nix
  options.modules.base = with types; {

    # Files relative to / root
    files = mkOption {
      description = "System files to preserve";
      type = listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Directories relative to / root
    dirs = mkOption {
      description = "System directories to preserve";
      type = listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

  };


  config = mkIf cfg.enable {

    # Script to wipe the root subvolume at boot
    boot.initrd.postDeviceCommands = mkBefore (builtins.readFile ./initrd.sh);

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${dir}" = {
        hideMounts = true;

        # System files
        files = cfg.files;

        # System directories
        directories = [
          "/etc/nixos"
          "/etc/NetworkManager/system-connections"
          "/var/lib"  
          "/var/log"  
          "/home"  
        ] ++ cfg.dirs;

      };
    };

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Maintain machine identification
    environment.etc."machine-id".source = "${dir}/etc/machine-id";

    # Maintain ssh host keys
    services.openssh = mkIf config.services.openssh.enable {
      hostKeys = [{
        path = "${dir}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      } {
        path = "${dir}/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }];
    };

  };

}
