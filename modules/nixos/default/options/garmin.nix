{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hardware.garmin;
  inherit (builtins) elemAt length split;
  idVendor = split ":" cfg.deviceId |> (list: (elemAt list 0));
  idProduct = split ":" cfg.deviceId |> (list: (elemAt list (length list - 1)));
  enable =
    if idVendor != "" && idProduct != ""
    then true
    else false;
in {
  options.hardware.garmin = {
    deviceId = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "091e:4cda";
      description = "USB ID of Garmin device (VID:PID)";
    };
  };

  config = lib.mkIf enable {
    services.udev.extraRules = ''
      # Automount Garmin device when detected
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${idVendor}", ATTR{idProduct}=="${idProduct}", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="garmin-mount.service"
      ACTION=="remove", SUBSYSTEM=="usb", ATTR{idVendor}=="${idVendor}", ATTR{idProduct}=="${idProduct}", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="garmin-unmount.service"
    '';

    systemd.user.services.garmin-mount = {
      description = "Mount Garmin device via GVFS (gio)";
      wantedBy = ["default.target"];
      after = ["graphical.target"];
      serviceConfig.Type = "oneshot";
      path = with pkgs; [coreutils gawk glib];
      script =
        # bash
        ''
          is_mounted() {
            awk '
              $1 ~ /^Mount\([0-9]+\):$/ && $(NF - 1) == "->" &&
              $NF ~ /^mtp:\/\/${idVendor}_${idProduct}([_\/]|$)/ { mounted = 1 }
              END { exit !mounted }
            ' <<< "$1"
          }

          # udev can run before GVFS lists the watch. Allow five discovery waits.
          for attempt in {1..6}; do
            listing="$(gio mount -li)"
            if is_mounted "$listing"; then
              exit 0
            fi

            uri="$(awk '/activation_root=mtp:\/\/${idVendor}_${idProduct}([_\/]|$)/ {sub(/^activation_root=/, "", $1); print $1; exit}' <<< "$listing")"
            if [ -n "$uri" ]; then
              if gio mount "$uri"; then
                exit 0
              else
                status=$?
              fi

              # Another automounter may have won the race. Keep other failures.
              if listing="$(gio mount -li)" && is_mounted "$listing"; then
                exit 0
              fi
              exit "$status"
            fi

            if [ "$attempt" -lt 6 ]; then
              sleep 1
            fi
          done

          # No watch at login is normal; a later udev start can try again.
          echo "No Garmin device listed; skipping mount after discovery retries."
        '';
    };

    systemd.user.services."garmin-unmount" = {
      description = "Unmount Garmin device via GVFS (gio)";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [coreutils gawk glib];
      script =
        # bash
        ''
          # Extract the activation_root by parsing the output of gio mount -li
          uri="$(gio mount -li | awk '/activation_root=mtp:\/\/${idVendor}_${idProduct}/{print $1}' | cut -d= -f2)"

          # Unmount the device
          gio mount -u "$uri"
        '';
    };
  };
}
