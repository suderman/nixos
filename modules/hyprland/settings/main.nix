{ lib, pkgs, this, ... }: let 

  inherit (lib) mkDefault; 
  inherit (this.lib) mkShellScript;

  init = mkShellScript {
    inputs = with pkgs; [ coreutils ]; text = ''
      # Temporary symlink
      "ln -sf $XDG_RUNTIME_DIR/hypr /tmp/hypr"
    '';
  };

in {

  # default display
  monitor = [ ", preferred, 0x0, 1" ];

  # Let xwayland be tiny, not blurry
  xwayland.force_zero_scaling = true;

  # Execute your favorite apps at launch
  exec-once = [
    "${init}"
    "waybar"
    "mako"
    "swww-daemon"
  ];

  input = {
    kb_layout = "us";
    # follow_mouse = mkDefault 2;
    follow_mouse = mkDefault 1;
    natural_scroll = true;
    scroll_factor = 1.5;
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
    # layout = mkDefault "master";
    layout = mkDefault "dwindle";
    # no_cursor_warps = mkDefault false;
    resize_on_border = mkDefault true;
  };

  master.new_is_master = mkDefault true;

  dwindle = {
    preserve_split = true;
    smart_split = false;
    pseudotile = true;
    special_scale_factor = 0.9;
  };

  gestures.workspace_swipe = mkDefault true;

  misc = {
    mouse_move_enables_dpms = mkDefault true;
    key_press_enables_dpms = mkDefault true;
    enable_swallow = mkDefault true;
    swallow_regex = mkDefault "^(Alacritty|kitty|footclient)$";
    focus_on_activate = mkDefault false;
    # cursor_zoom_factor = mkDefault 1;
  };

  binds = {
     workspace_back_and_forth = mkDefault true;
  };

}


# bind = SUPER, z, fullscreen
# bind = SUPER ALT, z, togglefloating
# # bind=SUPER,F,fullscreen
#
# bindm = SUPER ALT, mouse:272, resizewindow
#
# bind = , f8, togglefloating
# bind = , f9, exec, sleep 1 && hyprctl dispatch dpms off
# bind = , f10, exec, sleep 1 && hyprctl dispatch dpms on
# # bind = SUPER SHIFT, z, exec, sleep 1 && hyprctl dispatch dpms toggle
#
# # bind=SUPER,grave,togglespecialworkspace,
#
# workspace = special:term, on-created-empty:kitty
# workspace = special:lf, on-created-empty:kitty -e lf
# # workspace = special:dots, on-created-empty:foot --working-directory=$HOME/dotfiles/ -e nvim # This seems overkill
# workspace = special:term, gapsout:30
# workspace = special:lf, gapsout:20
# workspace = special:dots, gapsout:20
#
# workspace = special, gapsout:30,gapsin:30
# bind = SUPER, S, togglespecialworkspace
# bind = SUPER ALT, S, movetoworkspace, special
# bind = SUPER ALT, T, togglespecialworkspace, term
# bind = SUPER ALT, L, togglespecialworkspace, lf
# bind = SUPER ALT, N, togglespecialworkspace, dots
#
# animation = specialWorkspace, 1, 3, default, slidefadevert -50%
#
# general { 
#   layout = dwindle
#   # layout = master
# }
#
# master {
#   orientation = center;
#   always_center_master = true;
# }
#
# dwindle {
#   preserve_split = true
#   smart_split = true 
#   pseudotile = true
#   special_scale_factor = 0.9
# }
