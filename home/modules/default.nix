{ ... }: 
{
  imports = [
    ./gtk.nix
    ./persist.nix
    ./wayland.nix
    ./xdg.nix
  ];
}
