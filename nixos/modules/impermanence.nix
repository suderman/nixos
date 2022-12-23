{ inputs, config, lib, username, ... }: 

let 
  inherit (lib) mkOption types;
  dir = "/nix/state";

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  options = with types; {

    # Persist in /nix
    persist = {

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

  config = {

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${dir}" = with config; {
        hideMounts = true;

        # System files
        files = persist.files;

        # System directories
        directories = [
          "/etc/nixos"        # nixos configuration
          "/var/lib/systemd"  # systemd
          "/var/log"          # logs
        ] ++ persist.dirs;

        # Also persist user data
        users."${username}" = with config.home-manager.users."${username}"; {

          # Home files
          files = [
            ".nix-channels" # nix configuration
          ] ++ persist.files;

          # Home directories
          directories = persist.dirs;

        };
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
