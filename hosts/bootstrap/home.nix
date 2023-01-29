{ config, lib, pkgs, ... }: {

  imports = [ ../shared/user ];

  home.packages = with pkgs; [ 
    neofetch
    yo
  ];

}
