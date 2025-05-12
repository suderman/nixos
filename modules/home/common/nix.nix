{ flake, lib, ... }: let

  inherit (lib) hasPrefix partition; 

  caches = let part = (partition (value: (hasPrefix "https://" value)) flake.caches); in {
    urls = part.right;
    keys = part.wrong;
  };

in { 

  # Enable flakes and pipes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes pipe-operators";
  };

  # Binary caches
  nix.settings = {
    substituters = caches.urls;  
    trusted-public-keys = caches.keys;
  };

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";

}
