{ inputs, config, lib, nixos, ... }: 

let 
  inherit (lib) mkIf mkOption types;

in {

  options.persist = with types; {

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

}
