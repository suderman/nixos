# Use systemd tmpfiles rules to create files, directories, symlinks and permissions changes
# https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html
{ config, lib, this, ... }: let

  inherit (lib) mkOption types;
  inherit (this.lib.rules) mkRules;

in {

  # Add "file" option
  options.file = mkOption { type = types.attrs; default = {}; };

  # Add these paths to list found in systemd.tmpfiles.rules 
  config.systemd.tmpfiles.rules = mkRules config.file; 

}
