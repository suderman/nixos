{...}: {
  wayland.windowManager.hyprland.settings = {
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
