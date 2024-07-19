{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) attrValues concatStringsSep mapAttrs;
  inherit (lib) mkIf;

  dir = "$XDG_RUNTIME_DIR/sinks";
  sinks = attrValues( mapAttrs( id: name: ( 
    ''$DRY_RUN_CMD echo "${name}" > "${dir}/${id}"''
  ) ) {

    # all
    "bluez_output.AC_3E_B1_9F_43_35.1" = "Pixel Buds Pro";
    "alsa_output.usb-Apple__Inc._USB-C_to_3.5mm_Headphone_Jack_Adapter_DWH22420D3TJKLTAT-00.analog-stereo" = "USB Headphones";

    # cog
    "alsa_output.pci-0000_00_1f.3.analog-stereo" = "Main Headphones/Speakers";
    "alsa_output.pci-0000_00_1f.3.hdmi-stereo" = "HDMI Audio"; # hyperdrive hub

    # kit
    "alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink" = "Main Headphones";
    "alsa_output.pci-0000_01_00.1.pro-output-3" = "HDMI Audio"; # nvidia gpu

    # pod
    "alsa_output.pci-0000_00_1b.0.analog-stereo" = "Main Headphones/Speakers";
    "alsa_output.pci-0000_05_00.1.hdmi-stereo-extra3" = "HDMI Audio"; # amd gpu

  } );

in {

  config = mkIf cfg.enable {
    home.activation.writeSinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD rm -rf ${dir}
      $DRY_RUN_CMD mkdir -p ${dir}
      ${concatStringsSep "\n" sinks}
    '';
  };

}
