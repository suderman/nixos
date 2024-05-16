{ config, lib, pkgs, inputs, ... }: let 

  cfg = config.modules.hyprland;
  inherit (builtins) readFile;
  inherit (lib) mkIf;

in {

  # AGS home manager module
  imports = [ inputs.ags.homeManagerModules.default ];

  # https://aylur.github.io/ags-docs/config
  config = mkIf cfg.enable {

    programs.ags = {
      enable = true;

      # null or path, leave as null if you don't want hm to manage the config
      configDir = ./.;

      # additional packages to add to gjs's runtime
      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
        accountsservice
      ];

    };

  };

}
