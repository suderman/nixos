{ pkgs, this, ... }: let 
  inherit (this.lib) apps ls mkShellScript;
in {

  # Packages
  home.packages = with pkgs; [ 
    bat cowsay eza fish killall lf 
    linode-cli lsd mosh nano ncdu neofetch
    nnn owofetch rclone ripgrep sl sysz
    tealdeer wget lazygit lazydocker parted
    imagemagick
    yt-dlp # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
    tdesktop slack
    micro xorg.xeyes
    jetbrains-mono
    gst_all_1.gst-libav
    _1password-cli _1password-gui 
    junction 
  ];

  programs.zwift.enable = true;
  programs.chromium.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  programs.yazi.enable = true;

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.lux";
  };

}
