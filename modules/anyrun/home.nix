# modules.anyrun.enable = true;
{ config, pkgs, lib, inputs, ... }: 

let 

  cfg = config.modules.anyrun;
  inherit (lib) mkIf mkOption;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dir = "/etc/nixos/modules/anyrun";
  fonts = with pkgs; [ lexend ];

in {

  options.modules.anyrun = {
    enable = lib.options.mkEnableOption "anyrun"; 
    package = mkOption {
      type = with lib.types; nullOr package;
      default = inputs.anyrun.packages.${pkgs.system}.anyrun;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ fonts;
    xdg.configFile."anyrun/config.ron".source = mkOutOfStoreSymlink "${dir}/config.ron";
    xdg.configFile."anyrun/style.css".source = mkOutOfStoreSymlink "${dir}/style.css";
    xdg.configFile."anyrun/plugins".source = mkOutOfStoreSymlink "${cfg.package}/lib";
  };

}
