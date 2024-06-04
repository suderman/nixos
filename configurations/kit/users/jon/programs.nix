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

    _1password _1password-gui 
    inkscape junction libreoffice newsflash
    unstable.nodePackages_latest.immich
    junction 

    zwift coffee
    bin-foo bin-bar

    tauon # jellyfin/plex/local music player

    pavucontrol ncpamixer pamixer pamix

  ];

  # modules.firefox.enable = true;
  programs.chromium.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  # programs.neovim.enable = true;

  programs.wezterm.enable = false;
  programs.foot.enable = false;
  # pipewire-alsa pipewire-audio pipewire-docs pipewire-jack pipewire-media-session pipewire-pulse

  # terminal du jour
  modules.kitty.enable = true;
  modules.yazi.enable = true;

  modules.keyd.enable = true;

}
