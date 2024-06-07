# wayland.windowManager.hyprland.enable = true; 
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkDefault mkMerge mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) destabilize ls mkShellScript;

in {

  imports = ls { path = ./programs; dirsWith = [ "home.nix" ]; } ++

    # Flake home-manager module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/hm-module.nix
    [ inputs.hyprland.homeManagerModules.default ];

  config = mkIf cfg.enable {

    # If keyd is used, also update systemd target
    systemd.user.services.keyd.Unit = {
      After = [ "hyprland-session.target" ];
      Requires = [ "hyprland-session.target" ];
    };

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

    # gtk.theme.package = pkgs.dracula-theme;
    # gtk.theme.name = "dracula";

    wayland.windowManager.hyprland = {
      systemd.variables = ["--all"];
      systemd.enableXdgAutostart = true;

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
