# modules.hyprland.enable = true;
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkDefault mkMerge mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) destabilize ls mkShellScript;

in {

  imports = ls ./config ++

    # Flake home-manager module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/hm-module.nix
    [ inputs.hyprland.homeManagerModules.default ];

  options.modules.hyprland = with types; {
    enable = mkEnableOption "hyprland"; 
    nvidia = mkEnableOption "hyprland"; 
    preSettings = mkOption { type = anything; default = {}; };
    settings = mkOption { type = anything; default = {}; };
  };

  config = mkIf cfg.enable {

    modules.kitty.enable = true;
    # modules.eww.enable = true;
    # modules.waybar.enable = true;
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

      swww

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
      plugins = [ 
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo 
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprwinwrap 
      ];

      settings = mkMerge [ 
        cfg.preSettings 
        ( import ./settings/main.nix { inherit lib; } )
        ( import ./settings/graphics.nix { inherit lib; } )
        ( import ./settings/rules.nix { inherit lib; } )
        ( import ./settings/binds.nix { inherit lib; } )
        ( if cfg.nvidia then import ./settings/nvidia.nix { inherit lib; } else {} )
        cfg.settings 
      ];

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
