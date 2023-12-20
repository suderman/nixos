{ config, lib, this, ... }: let

  inherit (lib) mkOption types;
  inherit (this.lib) mkRules;

in {

  # Add "file" option
  options.file = mkOption { type = types.attrs; default = {}; };

  # Add these paths to list found in systemd.tmpfiles.rules 
  config.systemd.tmpfiles.rules = mkRules config.file; 

}
