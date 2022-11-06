{ pkgs, ... }: {

  imports = [
    ./git.nix
    ./tmux.nix
    ./zsh.nix
  ];

}
