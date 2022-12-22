{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;
  dir = "/nix/home";

in {
  
  imports = [ "${inputs.impermanence}/home-manager.nix" ];

  options = with types; {

    # Persist in /nix
    state = {

      # Files relative to ~ home
      files = mkOption {
        description = "Additional user state files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".bash_history" ];
      };

      # Directories relative to ~ home
      dirs = mkOption {
        description = "Additional user state directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".var" ];
      };

    };

  };

  config = {

    # Configuration impermanence module
    home.persistence = {

      # State stored on subvolume
      "${dir}" = {
        allowOther = true;
        files = config.state.files;
        directories = config.state.dirs;
      };

    };

  };

}
