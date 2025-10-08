{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hardware.bluetooth.enable {
    # Bluetuith client, and throw in bluetui as well
    environment.systemPackages = [
      pkgs.bluez
      pkgs.unstable.bluetuith
      pkgs.bluetui
    ];

    # Programs provided by bluez:
    # advtest avinfo avtest bcmfw bdaddr bluemoon bluetooth-player bluetoothctl bluetoothd
    # bluez-list-devices bluez-monitor-bluetooth bluez-simple-agent bluez-test-adapter bluez-test-device
    # bneptest btattach btconfig btgatt-client btgatt-server btinfo btiotest btmgmt btmon btmon-logger
    # btpclient btpclientctl btproxy btsnoop check-selftest ciptool cltest create-image eddystone
    # gatt-service gatttool hciattach hciconfig hcidump hcieventmask hcisecfilter hcitool hex2hcd hid2hci
    # hwdb ibeacon isotest l2ping l2test mcaptest mesh-cfgclient mesh-cfgtest meshctl mpris-proxy nokfw
    # obex-client-tool obex-server-tool obexctl obexd oobtest rctest rfcomm rtlfw scotest sdptool seq2bseq
    # test-runner

    # Root config for bluetuith (vim bindings)
    system.activationScripts.bluetuith = ''
      mkdir -p /root/.bluetuith
      printf '${builtins.toJSON {
        theme = {};
        receive-dir = "";
        keybindings = {
          NavigateDown = "j";
          NavigateUp = "k";
          Menu = "l";
          Close = "h";
          Quit = "q";
        };
      }}' >/root/.bluetuith/bluetuith.conf
    '';

    # Persist bluetooth pairings between reboots
    persist.storage.directories = ["/var/lib/bluetooth"];
  };
}
