{ flake, config, lib, ... }: {

  imports = [
    flake.homeModules.common
  ];

  home.stateVersion = "24.11";
  systemd.user.startServices = "sd-switch";

  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

}
