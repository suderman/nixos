# osConfig.programs.hyprland.enable = true;
{ config, osConfig, lib, pkgs, this, inputs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  oscfg = osConfig.programs.hyprland;
  inherit (lib) concatStringsSep ls mkIf mkMerge mkOption mkShellScript removeSuffix types;

in {

  imports = ls { path = ./programs; dirsWith = [ "home.nix" ]; } ++

    # Flake home-manager module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/hm-module.nix
    [ inputs.hyprland.homeManagerModules.default ];

  options.wayland.windowManager.hyprland.systemd.target = mkOption {
    type = types.str;
    default = "hyprland-ready.target";
  };

  config = mkIf oscfg.enable {

    # Add target that is enabled by exec-once at the top of the configuration
    systemd.user.targets."${removeSuffix ".target" cfg.systemd.target}".Unit = {
      Description = "Hyprland compositor session after dbus-update-activation-environment";
      Requires = [ "hyprland-session.target" ];
    };

    # Add these to my path
    home.packages = let

      # Ensure portals and other systemd user services are running
      # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
      bounce = mkShellScript {
        inputs = with pkgs; [ systemd ]; name = "bounce"; text = let 
          restart = name: "sleep 1 && systemctl --user stop ${name} && systemctl --user start ${name}";
        in concatStringsSep "\n" [ 

          # Ensure portals and other systemd user services are running
          # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
          ( restart "xdg-desktop-portal-hyprland" )
          ( restart "xdg-desktop-portal-gtk" )
          ( restart "xdg-desktop-portal" )
          ( restart "hyprland-ready.target" )

        ];
      };

    in with pkgs; [ 
      bounce
      inputs.hyprswitch.packages."${pkgs.stdenv.system}".default
      brightnessctl
      # pamixer
      # ncpamixer
      font-awesome
      wezterm
      swww
      wlogout # logout menu
      wl-clipboard # copying and pasting
      hyprpicker  # color picker
      hyprcursor
      wf-recorder # screen recording
      grim # taking screenshots
      slurp # selecting a region to screenshot
    ];

    programs = {
      kitty.enable = true;
      chromium.enable = true;
    };

    # I'll never remember the H
    home.shellAliases = {
      hyprland = "Hyprland";
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

      plugins = [ 
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo 
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprwinwrap 
      ];

      settings = let
        args = { 
          inherit lib this; 
          pkgs = pkgs // { inherit (inputs.hyprland.packages.${pkgs.system}) hyprland; };
        };
      in mkMerge ( map ( f: import f args ) ( ls ./settings ) );

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
