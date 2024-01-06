# modules.hyprland.enable = true;
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkDefault mkMerge mkOption types;
  inherit (lib.options) mkEnableOption;
  inherit (this.lib) destabilize mkShellScript;

in {

  imports =

    # Flake home-manager module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/hm-module.nix
    [ inputs.hyprland.homeManagerModules.default ] ++

    # Unstable upstream home-manager module
    # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
    ( destabilize inputs.home-manager-unstable "services/window-managers/hyprland.nix" );


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

      settings = mkMerge [ cfg.preSettings {

        monitor = [
          # default display
          ", preferred, 0x0, 1"
        ];

        # Let xwayland be tiny, not blurry
        xwayland.force_zero_scaling = true;

        # Execute your favorite apps at launch
        exec-once = [
          "hyprpaper"
          "mako"
        ];

        env = [
          "XCURSO_SIZE,84"
        ];

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          natural_scroll = true;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            clickfinger_behavior = true;
            scroll_factor = 0.7;
          };
          scroll_method = "2fg";
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        # "device:epic-mouse-v1" = { sensitivity = -0.5; };

        general = {
          gaps_in = mkDefault 4;
          gaps_out = mkDefault 8;
          border_size = mkDefault 2;
          "col.active_border" = mkDefault "rgb(89b4fa) rgb(cba6f7) 270deg";
          "col.inactive_border" = mkDefault "rgb(11111b) rgb(b4befe) 270deg";
          layout = mkDefault "master";
          no_cursor_warps = mkDefault false;
          resize_on_border = mkDefault true;
        };

        gestures.workspace_swipe = mkDefault true;
        master.new_is_master = mkDefault true;

        misc = {
          disable_hyprland_logo = mkDefault true;
          disable_splash_rendering = mkDefault true;
          mouse_move_enables_dpms = mkDefault true;
          key_press_enables_dpms = mkDefault true;
          enable_swallow = mkDefault true;
          swallow_regex = mkDefault "^(Alacritty|kitty|footclient)$";
          focus_on_activate = mkDefault true;
          animate_manual_resizes = mkDefault true;
          animate_mouse_windowdragging = mkDefault true;
          # suppress_portal_warnings = true;
        };

        decoration = {
          rounding = mkDefault 15;
          drop_shadow = mkDefault true;
          shadow_range = mkDefault 4;
          shadow_render_power = mkDefault 3;
          "col.shadow" = mkDefault "rgba(1a1a1aee)";
          dim_inactive = mkDefault false;
          dim_strength = mkDefault 0.1;
          dim_special = mkDefault 0;
        };

        animations = {
          enabled = mkDefault true;
          bezier = mkDefault [
            "md3_standard, 0.2, 0.0, 0, 1.0"
            "md3_decel, 0.05, 0.7, 0.1, 1"
            "md3_accel, 0.3, 0, 0.8, 0.15"
            "overshot, 0.05, 0.9, 0.1, 1.05"
            "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
            "win10, 0, 0, 0, 1"
            "gnome, 0, 0.85, 0.3, 1"
            "funky, 0.46, 0.35, -0.2, 1.2"
          ];
          animation = mkDefault [
           "windows, 1, 2, md3_decel, slide"
           "border, 1, 10, default"
           "fade, 1, 0.0000001, default"
           "workspaces, 1, 4, md3_decel, slide"
          ];
        };

        bind = [
          "SUPER, Return, exec, kitty"
          "SUPER, Q, killactive,"
          "SUPERSHIFT, Q, exit,"
          "SUPER, E, exec, nautilus"
          "SUPER, F, exec, firefox"
          "SUPER, Escape, togglefloating,"
          "SUPER, Space, exec, tofi-drun --drun-launch=true"
          "SUPER, N, layoutmsg, swapnext"
          "SUPER, P, layoutmsg, swapprev"
          "SUPER, B, layoutmsg, swapwithmaster master"
          "SUPER, G, layoutmsg, addmaster "
          "SUPER+SHIFT, G, layoutmsg, removemaster"

          # Move focus with mainMod + arrow keys
          "SUPER, H, movefocus, l"
          "SUPER, J, movefocus, d"
          "SUPER, K, movefocus, u"
          "SUPER, L, movefocus, r"

          "SUPERSHIFTCONTROL, J, layoutmsg, swapnext"
          "SUPERSHIFTCONTROL, K, layoutmsg, swapprev"
          "SUPER, M, layoutmsg, swapwithmaster master"

          # Switch workspaces with mainMod + [0-9]
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"
          "SUPER, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"
          "SUPER SHIFT, 9, movetoworkspace, 9"
          "SUPER SHIFT, 0, movetoworkspace, 10"

          # Scroll through existing workspaces with mainMod + scroll
          "SUPER, mouse_down, workspace, e+1"
          "SUPER, mouse_up, workspace, e-1"
        ];

        binde = [
          "SUPERSHIFT, H, resizeactive, -80 0"
          "SUPERSHIFT, J, resizeactive, 0 80"
          "SUPERSHIFT, K, resizeactive, 0 -80"
          "SUPERSHIFT, L, resizeactive, 80 0"

          # Screen brightness
          ", XF86MonBrightnessUp,exec,brightnessctl set +5%"
          ", XF86MonBrightnessDown,exec,brightnessctl set 5%-"

          # Volume control
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];

        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
          "SUPERSHIFT, mouse:272, resizewindow"
        ];

      } cfg.settings ];

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
