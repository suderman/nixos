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
    isy lapce micro quickemu xorg.xeyes
    jetbrains-mono
    gst_all_1.gst-libav
    libsForQt5.kdenlive

    inkscape junction libreoffice newsflash
    unstable.nodePackages_latest.immich
    junction 

    bin-foo bin-bar coffee

    tauon # jellyfin/plex/local music player

    pavucontrol ncpamixer pamixer pamix

  ];

  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  # programs.neovim.enable = true;

  programs.wezterm.enable = false;
  programs.foot.enable = false;
  programs.yazi.enable = true;

  programs.zwift.enable = true;

  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=x11"
    ];
  };

  programs.silverbullet = {
    enable = true;
    url = "https://silverbullet.lux";
    platform = "x11";
  };

  programs.immich = {
    enable = true;
    url = "https://immich.lux";
    platform = "x11";
  };

  programs.lunasea = {
    enable = true;
    url = "https://lunasea.lux";
    platform = "x11";
  };

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.lux";
    platform = "x11";
  };

}
