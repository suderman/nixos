{ pkgs, this, ... }: let 

  inherit (this.lib) apps ls mkShellScript;
  coffee = mkShellScript { name = "coffee"; text = ./bin/coffee.sh; };

in {

  # Packages
  home.packages = with pkgs; [ 

    # cowsay owofetch sl
    bat eza fish killall lf 
    linode-cli lsd mosh nano ncdu neofetch
    nnn rclone ripgrep sysz
    tealdeer wget yo lazygit lazydocker parted
    imagemagick

    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
    yt-dlp 

    # tdesktop slack
    isy micro 
    # jetbrains-mono
    gst_all_1.gst-libav
    # libsForQt5.kdenlive

    # junction 
    bin-foo bin-bar coffee

    # Re-enable these after this is fixed:
    # https://github.com/NixOS/nixpkgs/issues/332957
    # quickemu lapce tauon 

    shotcut
    davinci-resolve

  ];

  # programs.bluebubbles.enable = true;
  programs.foot.enable = false;
  # programs.gimp.enable = true;
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.wezterm.enable = false;
  # programs.yazi.enable = true;
  programs.zsh.enable = true;
  # programs.zwift.enable = true;

  programs.chromium = {
    enable = true;
    # commandLineArgs = [
    #   "--enable-features=UseOzonePlatform"
    #   "--ozone-platform=wayland"
    #   # "--ozone-platform=x11"
    # ];
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

  programs.home-assistant = {
    enable = true;
    url = "https://hass.hub";
    platform = "x11";
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
