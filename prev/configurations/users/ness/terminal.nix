{ config, lib, pkgs, profiles, ... }: {

  imports = with profiles; [
    terminal # tui programs
  ];

}
