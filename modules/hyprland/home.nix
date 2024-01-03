# modules.hyprland.enable = true;
{ config, pkgs, lib, inputs, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf;

in {

  # Import hyprland module
  imports = [ 
    inputs.hyprland.homeManagerModules.default 
  ];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
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

    ];

    # I'll never remember the H
    home.shellAliases = {
      hyprland = "Hyprland";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # plugins = [ inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars ];
      # recommendedEnvironment = true;
      extraConfig = builtins.readFile ./hyprland.conf + "\n\n" + ''
        source = ~/.config/hypr/local.conf
      '';
    };

    # Local override config
    home.activation.hyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/hypr
      $DRY_RUN_CMD touch $HOME/.config/hypr/local.conf
    '';

  };

}
