# Add directories or files to persist list
#
# > Add a system directory or file
# persist.dirs = [ "/var/lib/systemd" ];
# persist.files = [ "/etc/machine-id" ];
#
# > Add a home directory or file (relative from $HOME)
# persist.home.dirs = [ ".local/share/keyrings" ];
# persist.home.files = [ ".nix-channels" ];

{ inputs, config, lib, username, ... }: 

let 
  inherit (lib) mkOption types;
  hm-config = config.home-manager.users."${username}";
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

      # Files relative to ~/ home
      home.files = mkOption {
        description = "Home files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".bash_history" ];
      };

      # Directories relative to ~/ home
      home.dirs = mkOption {
        description = "Home directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".var" ];
      };

    };

  };

  config = {

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "${dir}" = {
        hideMounts = true;

        # System files
        files = config.persist.files;

        # System directories
        directories = [
          "/etc/nixos"        # nixos configuration
          "/var/lib/systemd"  # systemd
          "/var/log"          # logs
        ] ++ config.persist.dirs;

        # Also persist user data
        users."${username}" = {

          # Home files
          files = [
            ".nix-channels" # nix configuration
          ] ++ config.persist.home.files ++ hm-config.persist.files;

          # Home directories
          directories = config.persist.home.dirs ++ hm-config.persist.dirs;

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
