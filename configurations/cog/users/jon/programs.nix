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

    _1password-cli _1password-gui darktable digikam
    inkscape junction libreoffice newsflash
    unstable.nodePackages_latest.immich

    withings-sync coffee
    bin-foo bin-bar

    # Re-enable these after this is fixed:
    # https://github.com/NixOS/nixpkgs/issues/332957
    # quickemu lapce tauon 

    pavucontrol ncpamixer pamixer pamix

    gnome-disk-utility

    asunder
    lame

    shizuku # connect android to pc and run

  ];

  programs.bluebubbles.enable = true;
  programs.chromium.enable = true;
  programs.foot.enable = false;
  programs.gimp.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.wezterm.enable = false;
  programs.yazi.enable = true;
  programs.zsh.enable = true;
  programs.zwift.enable = true;

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

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.lux";
  };

  services.flatpak = {
    enable = true;
    apps = [
      "io.github.dvlv.boxbuddyrs"
      "io.gitlab.zehkira.Monophony"
      "org.emptyflow.ArdorQuery"
      "com.github.treagod.spectator"
    ];
  };

}
