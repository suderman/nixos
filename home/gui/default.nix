{ pkgs, ... }: {

  imports = [
    ./wayland.nix
    ./wezterm.nix
    ./xdg.nix
  ];

}
