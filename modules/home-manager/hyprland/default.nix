# modules.hyprland.enable = true;
{ config, pkgs, lib, inputs, ... }: 

let 

  cfg = config.modules.hyprland;

  inherit (lib) mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  dir = "/etc/nixos/modules/home-manager/hyprland";

in {

  # Import hyprland module
  imports = [ 
    inputs.hyprland.homeManagerModules.default 
  ];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
  };

  config = mkIf cfg.enable {

    modules.eww.enable = true;
    # modules.anyrun.enable = true;

    # programs.waybar = {
    #   enable = true;
    #   package = pkgs.unstable.waybar;
    # };

    home.packages = with pkgs; [ 
      gnome.nautilus
      wofi
      tofi
      wezterm
      unstable.waybar
      hyprpaper
      brightnessctl
      mako
      # pamixer
      # ncpamixer

      swaybg # the wallpaper
      swayidle # the idle timeout
      swaylock # locking the screen
      wlogout # logout menu
      wl-clipboard # copying and pasting
      hyprpicker  # color picker
      wf-recorder # screen recording
      grim # taking screenshots
      slurp # selecting a region to screenshot

    ];

    # I'll never remember the H
    home.shellAliases = {
      hyprland = "Hyprland";
    };

    # xdg.configFile."hypr/local.conf".source = mkOutOfStoreSymlink "${dir}/local.conf";

    wayland.windowManager.hyprland = {
      enable = true;
      plugins = [
        # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      ];
      recommendedEnvironment = true;
      extraConfig = builtins.readFile ./hyprland.conf;
      # extraConfig = ''
      #   exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      #   source = ~/.config/hypr/local.conf
      # '';
    };

    home.activation.hyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD touch $HOME/.config/hypr/local.conf
    '';

  };

}
