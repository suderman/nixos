{ pkgs, this, ... }: let 

  inherit (this.lib) apps ls mkShellScript;
  coffee = mkShellScript { name = "coffee"; text = ./bin/coffee.sh; };

in {

  # Packages
  home.packages = with pkgs; [ 

    bat cowsay eza fish killall lf 
    linode-cli lsd mosh nano ncdu neofetch
    nnn owofetch rclone ripgrep sl sysz
    tealdeer wget yo lazygit lazydocker parted
    imagemagick

    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
    yt-dlp 

    tdesktop slack
    isy micro xorg.xeyes
    jetbrains-mono
    gst_all_1.gst-libav
    libsForQt5.kdenlive

    _1password-cli _1password-gui 
    junction 

    bin-foo bin-bar coffee

    # Re-enable these after this is fixed:
    # https://github.com/NixOS/nixpkgs/issues/332957
    # quickemu lapce tauon 

  ];

  programs.zwift.enable = true;
  programs.chromium.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  programs.wezterm.enable = false;
  programs.foot.enable = false;
  programs.yazi.enable = true;

  programs.silverbullet = {
    enable = true;
    url = "https://silverbullet.lux";
  };

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.lux";
  };

}
