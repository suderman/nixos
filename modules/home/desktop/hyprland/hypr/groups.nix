{
  config,
  lib,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    group = {
      merge_groups_on_drag = true;
      groupbar = with config.lib.stylix.colors; {
        enabled = true;
        font_size = 14; # looks like hyprbar's 11
        font_family = "sanserif";
        gradients = true;
        keep_upper_gap = false;
        height = 20;
        gradient_rounding = 20;
        gradient_rounding_power = "4.0";
        gradient_round_only_edges = false;
        rounding = 15;
        rounding_power = "4.0";
        round_only_edges = false;
        gaps_in = 10;
        gaps_out = 5;
        render_titles = true;
        indicator_height = 0; # 15
        indicator_gap = 0;

        # group background
        "col.locked_active" = lib.mkForce "rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},0.8)"; #b
        "col.locked_inactive" = lib.mkForce "rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},0.6)"; #b

        # group foreground
        text_color_locked_active = lib.mkForce "rgba(${base05-rgb-r},${base05-rgb-g},${base05-rgb-b},0.8)"; #a
        text_color_locked_inactive = lib.mkForce "rgba(${base05-rgb-r},${base05-rgb-g},${base05-rgb-b},0.8)"; #a

        # unlocked group background
        "col.active" = lib.mkForce "rgba(${base05-rgb-r},${base05-rgb-g},${base05-rgb-b},0.8)"; #a-light
        "col.inactive" = lib.mkForce "rgba(${base05-rgb-r},${base05-rgb-g},${base05-rgb-b},0.8)"; #a-light

        # unlocked group foreground
        text_color = lib.mkForce "rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},0.8)"; #b
        text_color_inactive = lib.mkForce "rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},0.8)"; #b
      };
    };

    bind = [
      # Disperse group (if exists) else kill window
      "super, q, exec, hypr-togglegrouporkill"

      # Prev window in group with super+comma [<]
      "super+shift, comma, changegroupactive, b"
      "super+shift, comma, lockactivegroup, lock"
      # Also respond to this key without shift
      "super, comma, changegroupactive, b"
      "super, comma, lockactivegroup, lock"

      # Next window in group with super+period [>]
      "super+shift, period, changegroupactive, f"
      "super+shift, period, lockactivegroup, lock"
      # Also respond to this key without shift
      "super, period, changegroupactive, f"
      "super, period, lockactivegroup, lock"

      # Rearrange window back inside a group
      "super+alt+shift, comma, movegroupwindow, b"
      "super+alt+shift, comma, lockactivegroup, lock"
      # Also respond to this key without shift
      "super+alt, comma, movegroupwindow, b"
      "super+alt, comma, lockactivegroup, lock"

      # Rearrange window forward inside a group
      "super+alt+shift, period, movegroupwindow, f"
      "super+alt+shift, period, lockactivegroup, lock"
      # Also respond to this key without shift
      "super+alt, period, movegroupwindow, f"
      "super+alt, period, lockactivegroup, lock"

      # Toggle group lock with super+alt click
      "super+alt, mouse:272, exec, hypr-togglegrouporlock"

      # Toggle group status & group lock
      "super, slash, exec, hypr-togglegrouporlock"
    ];
  };
}
