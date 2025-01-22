{ pkgs, lib, ... }: let 

  inherit (lib) ls mkShellScript;

  # example bash script
  coffee = mkShellScript { name = "coffee"; text = ./bin/coffee.sh; };

in {

  # cli packages
  home.packages = with pkgs; [ 

    bat cowsay eza fish killall lf 
    linode-cli lsd mosh nano ncdu neofetch
    nnn owofetch rclone ripgrep sl sysz
    tealdeer wget lazygit lazydocker parted
    imagemagick

    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
    yt-dlp 

    micro 

    _1password-cli 

    coffee
    bin-foo bin-bar

    # Re-enable these after this is fixed:
    # https://github.com/NixOS/nixpkgs/issues/332957
    # quickemu lapce tauon 

    ncpamixer pamixer pamix

    lame

    shizuku # connect android to pc and run

  ];

  programs.yazi.enable = true;
  programs.zsh.enable = true;

}
