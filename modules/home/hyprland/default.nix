# osConfig.programs.hyprland.enable = true;
{ config, lib, pkgs, flake, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkMerge mkOption removeSuffix types;
  inherit (flake.lib) ls;

in {

  imports = [
    flake.homeModules.desktop
  ] ++ ls ./settings ++ ls ./programs;

  options.wayland.windowManager.hyprland = {
    enablePlugins = lib.options.mkEnableOption "enablePlugins";
    systemd.target = mkOption {
      type = types.str;
      default = "hyprland-ready.target";
    };
  };


  config = {

    # I'll never remember the H
    home.shellAliases = {
      hyprland = "Hyprland";
    };

    home.packages = with pkgs; [ nerd-fonts.symbols-only ]; 

    # Add target that is enabled by exec-once at the top of the configuration
    systemd.user.targets."${removeSuffix ".target" cfg.systemd.target}".Unit = {
      Description = "Hyprland compositor session after dbus-update-activation-environment";
      Requires = [ "hyprland-session.target" ];
    };

    # Automatically enable home-manager module if nixos module is enabled
    wayland.windowManager.hyprland = {
      enable = true;

      systemd = {
        enable = true;
        enableXdgAutostart = true;
        variables = [ 
          "DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
        ];
        extraCommands = [
          "systemctl --user stop ${cfg.systemd.target}"
          "systemctl --user start ${cfg.systemd.target}" 
        ];
      };

      plugins = with pkgs.hyprlandPlugins; mkIf cfg.enablePlugins [ 
        # hypr-dynamic-cursors
      ];

      extraConfig = ''
        source = ~/.config/hypr/extra/hyprland.conf
      '';

    };

    # Enable user service for keyd to watch window focus changes  
    services.keyd.enable = true;

    # Persist extra config
    persist.directories = [ ".config/hypr/extra" ];
    tmpfiles.files = [ ".config/hypr/extra/hyprland.conf" ];

  };

}
