{ ... }: 
{
  imports = [
    ./chromium.nix
    ./git.nix
    ./kitty.nix
    ./packages.nix
    ./photo.nix
    ./tmux.nix
    ./wezterm.nix
    ./zsh.nix
  ];
}
