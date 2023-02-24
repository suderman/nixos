{ config, lib, pkgs, ... }: {

  base.enable = true;
  secrets.enable = false;

  home.packages = with pkgs; [ 
    neofetch
    yo
  ];

}
