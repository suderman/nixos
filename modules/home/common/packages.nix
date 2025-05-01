{ config, pkgs, perSystem, ... }: {

  home.packages = with pkgs; [ 
    bat 
    killall
    lf 
    lsd
    ripgrep
    sysz
    tealdeer
    wget
  ] ++ (with perSystem.self; [
    sv # wrapper for systemctl/journalctl
    ipaddr
    hello
  ]);

  programs = {
    git.enable = true;
    zsh.enable = true;
    fzf.enable = true;
    neovim.enable = true;
    direnv.enable = true;
  };

}
