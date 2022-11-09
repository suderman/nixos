{ pkgs, ... }: {

  imports = [
    ./wayland.nix
    ./wezterm.nix
    ./xdg.nix
    ./gtk.nix
    ./photo.nix
  ];

}
