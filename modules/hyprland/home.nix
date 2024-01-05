# modules.hyprland.enable = true;
{ config, pkgs, lib, inputs, this, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib.options) mkEnableOption;
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) destabilize mkShellScript;

  # Unstable home-manager hyprland module
  # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
  module = destabilize inputs.home-manager-unstable "services/window-managers/hyprland.nix";

in {

  # Import unstable module and hyprland settings
  imports = module ++ [ ./settings.nix ];

  options.modules.hyprland = with types; {
    enable = mkEnableOption "hyprland"; 
    preSettings = mkOption { type = anything; default = {}; };
    settings = mkOption { type = anything; default = {}; };
  };

  config = mkIf cfg.enable {

    modules.kitty.enable = true;
    modules.eww.enable = true;
    modules.waybar.enable = true;
    # modules.anyrun.enable = true;

    home.packages = with pkgs; [ 
      wofi
      tofi

      hyprpaper
      brightnessctl
      mako
      # pamixer
      # ncpamixer

      font-awesome
      firefox

      gnome.nautilus
      wezterm

      swaybg # the wallpaper
      swayidle # the idle timeout
      swaylock # locking the screen
      wlogout # logout menu
      wl-clipboard # copying and pasting
      hyprpicker  # color picker
      wf-recorder # screen recording
      grim # taking screenshots
      slurp # selecting a region to screenshot

      ( mkShellScript { name = "focus"; text = ./bin/focus.sh; } )

    ];

    # I'll never remember the H
    home.shellAliases = {
      hyprland = "Hyprland";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # plugins = [ inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars ];
      # extraConfig = builtins.readFile ./hyprland.conf + "\n\n" + ''
      extraConfig = ''
        source = ~/.config/hypr/extra.conf
      '';
    };

    # Extra config
    home.activation.hyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/hypr
      $DRY_RUN_CMD touch $HOME/.config/hypr/extra.conf
    '';

  };

}
