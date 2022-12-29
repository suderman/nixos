{ ... }: 
{
  imports = [
    ./chromium.nix
    ./git.nix
    ./packages.nix
    ./photo.nix
    ./tmux.nix
    ./wezterm.nix
    ./zsh.nix
  ];
}
