# state.enable = true;
#
# Add directories or files to persist
# state.dirs = [ "/var/lib/systemd" ];
# state.files = [ "/etc/machine-id" ];
#
{ inputs, config, lib, ... }: 

let 
  cfg = config.state;
  inherit (lib) mkOption types;
  dir = "/nix/state";

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  options = with types; {

    # Persist in /nix
    state = {

      # Enabled by default in configurations/shared 
      enable = lib.options.mkEnableOption "state"; 

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

  };

  config = lib.mkIf cfg.enable {

    # Script to wipe the root subvolume at boot
    boot.initrd.postDeviceCommands = lib.mkBefore (builtins.readFile ./initrd.sh);

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${dir}" = {
        hideMounts = true;

        # System files
        files = config.state.files;

        # System directories
        directories = [
          "/etc/nixos"
          "/etc/NetworkManager/system-connections"
          "/var/lib"  
          "/var/log"  
          "/home"  
        ] ++ config.state.dirs;

      };
    };

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Maintain machine identification
    environment.etc."machine-id".source = "${dir}/etc/machine-id";

    # Maintain ssh host keys
    services.openssh = lib.mkIf config.services.openssh.enable {
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
