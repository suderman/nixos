{ flake, config, lib, ... }: {

  home.stateVersion = "24.11";
  systemd.user.startServices = "sd-switch";

  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

}
