{ inputs, config, pkgs, lib, ... }: {

  imports = [ 
    ../. 
    ./hardware-configuration.nix 
  ];

  # Linode
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Packages
  environment.systemPackages = with pkgs; [];

  # Docker
  virtualisation.docker.enable = true;

  # Other
  # programs.nix-ld.enable = true;

}
