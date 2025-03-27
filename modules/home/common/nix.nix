{ flake, ... }: {

  # Enable flakes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";

}
