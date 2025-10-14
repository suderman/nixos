{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.satty;
  tomlFormat = pkgs.formats.toml {};
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.networking) hostName;
  pictures = config.xdg.userDirs.extraConfig.XDG_PICTURES_DIR or "${config.home.homeDirectory}/Pictures";
  class = "com.gabm.satty";
in {
  options.programs.satty = {
    enable = mkEnableOption "satty";
    package = mkOption {
      type = types.package;
      default = pkgs.unstable.satty;
    };
    settings = mkOption {
      type = tomlFormat.type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.wl-clipboard
    ];

    xdg.configFile."satty/config.toml" = lib.mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "satty-config.toml" cfg.settings;
    };

    programs.satty.settings = {
      general = {
        fullscreen = true;
        early-exit = true;
        corner-roundness = 12;
        initial-tool = "crop";
        copy-command = "wl-copy";
        annotation-size-factor = 1;
        output-filename = "${pictures}/Screenshots/${hostName}-%Y%m%d-%H%M%S.png";
        save-after-copy = false;
        default-hide-toolbars = false;
        primary-highlighter = "block"; # block, freehand
        disable-notifications = false;
        actions-on-right-click = []; # save-to-clipboard, save-to-file, exit
        actions-on-enter = ["save-to-file" "exit"]; # save-to-clipboard, save-to-file, exit
        actions-on-escape = ["exit"]; # save-to-clipboard, save-to-file, exit
        no-window-decoration = true;
      };
      # keybinds = {
      #   pointer = "p";
      #   crop = "c";
      #   brush = "b";
      #   line = "i";
      #   arrow = "z";
      #   rectangle = "r";
      #   ellipse = "e";
      #   text = "t";
      #   marker = "m";
      #   blur = "u";
      #   highlight = "g";
      # };
      font = {
        family = "Roboto";
        style = "Regular";
      };
      color-palette.palette = [
        "#dc143c"
        "#00ffff"
        "#a52a2a"
        "#ff1493"
        "#ffd700"
        "#008000"
      ];
    };

    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "fullscreen, class:${class}"
      ];
    };
  };
}
