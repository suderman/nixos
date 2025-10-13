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

  screenshot = pkgs.self.mkScript {
    name = "satty-screenshot";
    path = with pkgs; [cfg.package coreutils gawk grim libnotify pngquant wl-clipboard];
    text =
      # bash
      ''
        # Save location
        output="${pictures}/Screenshots/${hostName}-$(date '+%Y%m%d-%H%M%S').png"
        mkdir -p $(dirname $output)

        # Focused display when using hyprland
        display=""
        if command -v hyprctl &>/dev/null; then
          display="-o $(hyprctl monitors | awk '/Monitor/{mon=$2} /focused: yes/{print mon}')"
        fi

        # Capture display, pipe to satty for cropping/annotations, pipe to pngquant for optimization
        grim $display -t ppm -c - |
          satty --filename - --output-filename - |
          pngquant --quality=65-80 --speed=1 --strip --output "$output" -

        # Also copy saved file to clipboard
        wl-copy<"$output"

        # Notification when done
        notify-send 'Screenshot' "$output" \
          -i "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/16x16/devices/camera.svg"
      '';
  };
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
      screenshot
      pkgs.grim
      pkgs.slurp
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
  };
}
