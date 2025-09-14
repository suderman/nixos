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
