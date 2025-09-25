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
    else null;
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
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      path = with pkgs; [coreutils gawk glib];
      script =
        # bash
        ''
          # Extract the activation_root by parsing the output of gio mount -li
          uri="$(gio mount -li | awk '/activation_root=mtp:\/\/${idVendor}_${idProduct}/{print $1}' | cut -d= -f2)"

          # Mount the device
          gio mount "$uri"
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
