{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  options = with types; {

    # Persist in /nix/state
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
      "/nix/state" = {
        hideMounts = true;

        files = [ 
          # "/etc/machine-id"           # default: machine identification
        ] ++ config.state.files;

        directories = [
          # "/etc/nixos"                # default: nixos configuration
          # "/var/log"                  # default: logs
          # "/var/lib/AccountsService"  # possibly move this to gnome.nix?
        ] ++ config.state.dirs;

      };

    };

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

  };


}
