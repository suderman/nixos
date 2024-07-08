# programs.zwift.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.zwift;
  inherit (lib) getExe mkIf mkOption mkShellScript options types;

  # Assume "docker" available system-wide
  # including in "inputs" doesn't seem to work with nvidia-flavour
  zwift = mkShellScript {
    name = "zwift";
    inputs = with pkgs; [ hostname coreutils ]; 
    text = ./zwift.sh;
  };

in {

  options.programs.zwift = {
    enable = options.mkEnableOption "zwift"; 
  };

  config = mkIf cfg.enable {

    # Add to path
    home.packages = [ zwift ]; 

    # Add to launcher
    xdg.desktopEntries."zwiftapp.exe" = {
      name = "Zwift"; 
      icon = ./zwift.png; 
      exec = getExe zwift;
    };

    # Window rules
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tile,class:(zwiftapp.exe)" # don't float
      ];
    };

    # Keyboard shortcuts
    services.keyd.windows."zwiftapp-exe" = {};

  };

}
