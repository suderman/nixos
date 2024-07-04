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

    beeper tdesktop slack
    isy lapce micro quickemu xorg.xeyes
    jetbrains-mono
    gst_all_1.gst-libav
    libsForQt5.kdenlive

    _1password _1password-gui darktable digikam
    inkscape junction libreoffice newsflash
    unstable.nodePackages_latest.immich

    withings-sync zwift coffee
    bin-foo bin-bar

    tauon # jellyfin/plex/local music player

    pavucontrol ncpamixer pamixer pamix
  ];

  programs.chromium.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  programs.wezterm.enable = false;
  programs.foot.enable = false;
  programs.yazi.enable = true;

  programs.obs-studio = with pkgs.unstable; {
    enable = true;
    package = obs-studio;
    # plugins = [ obs-studio-plugins.wlrobs ];
  };

  programs.silverbullet = {
    enable = true;
    url = "https://silverbullet.lux";
  };

  programs.immich = {
    enable = true;
    url = "https://immich.lux";
  };

  programs.lunasea = {
    enable = true;
    url = "https://lunasea.lux";
  };

}
