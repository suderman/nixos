{ config, lib, pkgs, profiles, ... }: {

  # Include all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.terminal # tui programs
  ];

  # Create home folders
  xdg.userDirs = with config.home; {
    enable = true;
    createDirectories = false;
    desktop = "${homeDirectory}/Action";
    download = "${homeDirectory}/Downloads";
    documents = "${homeDirectory}/Documents";
    music = "${homeDirectory}/Music";
    pictures = "${homeDirectory}/Pictures";
    videos = "${homeDirectory}/Videos";
    # publicShare = "${homeDirectory}/public";
  };

}
