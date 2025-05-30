{ config, lib, ... }: let
  inherit (lib) mkAfter mkOption types;
in {

  options.tmpfiles = let 
    option = mkOption { 
      type = types.listOf types.anything; 
      default = []; 
    }; 
  in {
    directories = option; 
    files = option; 
    symlinks = option; 
  };

}
