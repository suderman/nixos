# programs.yazi.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.programs.yazi;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    programs.yazi = {

      # TODO: Try removing this override on next flake update
      # https://github.com/NixOS/nixpkgs/issues/353119#issuecomment-2453521926
      package = if this.stable then pkgs.yazi else pkgs.yazi.override {
        _7zz = ( pkgs._7zz.override { useUasm = true; } );
      };

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      enableFishIntegration = true;

      settings.manager = {
        sort_dir_first = true;
        linemode = "permissions";
        ratio = [ 1 3 4 ];
      };

      settings.preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 1920;
        max_height = 1080;
        image_quality = 90;
      };

      keymap.manager.prepend_keymap = [
        { run = "remove --force"; on = [ "d" ]; }
      ];

    } // (if this.stable then {} else {
      shellWrapperName = "y"; # doesn't yet exist in stable
    });

  };

}
