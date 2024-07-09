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
