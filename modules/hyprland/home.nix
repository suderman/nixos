# osConfig.programs.hyprland.enable = true;
{ config, osConfig, lib, pkgs, this, inputs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  oscfg = osConfig.programs.hyprland;
  inherit (lib) ls mkIf mkMerge mkOption removeSuffix types;

in {

  imports = ls ./settings ++ ls { path = ./programs; dirsWith = [ "home.nix" ]; } ++

    # Flake home-manager module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/hm-module.nix
    # [ inputs.hyprland.homeManagerModules.default ];
    [];

  options.wayland.windowManager.hyprland = {
    enablePlugins = lib.options.mkEnableOption "enablePlugins";
    # pkgs.hyprlandPlugins = mkOption {
    #   type = types.anything; # hyprland's own plugins from flake input
    #   default = inputs.hyprland-plugins.packages."${pkgs.stdenv.system}";
    # };
    systemd.target = mkOption {
      type = types.str;
      default = "hyprland-ready.target";
    };
  };


  config = mkIf oscfg.enable {

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
