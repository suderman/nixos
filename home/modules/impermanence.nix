{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;
  dir = "/nix/home";

in {
  
  imports = [ "${inputs.impermanence}/home-manager.nix" ];

  options = with types; {

    # Persist in /nix
    persist = {

      # Files relative to ~ home
      files = mkOption {
        description = "Home files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".bash_history" ];
      };

      # Directories relative to ~ home
      dirs = mkOption {
        description = "Home directories to preserve";
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
        files = config.persist.files;
        directories = config.persist.dirs;
      };

    };

  };

}
