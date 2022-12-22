{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;
  dir = "/nix/state";

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  options = with types; {

    # Persist in /nix
    state = {

      # Files relative to / root
      files = mkOption {
        description = "Additional system state files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/etc/machine-id" ];
      };

      # Directories relative to / root
      dirs = mkOption {
        description = "Additional system state directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/etc/nixos" ];
      };

    };

  };

  config = {

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${dir}" = {
        hideMounts = true;
        files = config.state.files;
        directories = [
          "/etc/nixos"                # default: nixos configuration
          "/var/log"                  # default: logs
          "/var/lib/systemd"          # default: systemd
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
