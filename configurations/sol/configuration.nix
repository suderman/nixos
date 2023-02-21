{ inputs, config, lib, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
  ];

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Hardware configuration
  hardware.linode.enable = true;

  # Services
  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.ddns.enable = true;

  # Programs
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  services.earlyoom.enable = true;

  services.traefik.enable = true;
  services.whoami.enable = true;
  services.whoogle.enable = false;

}
