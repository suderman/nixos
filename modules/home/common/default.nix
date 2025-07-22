{
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: {
  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  home.packages = with pkgs; [
    _1password-cli # op
    # calcure # calendar viewer
    # distrobox distrobox-tui
    imagemagick # animate compare composite conjure convert display identify import magick magick-script mogrify montage stream
    killall # kill by process name
    lame # mp3 codec
    lazydocker # docker tui
    lf
    linode-cli # control linode virtual servers
    lsd
    mosh # ssh despite bad networks
    nano # text editor
    ncdu # recover available disk space
    parted # manage disks
    perSystem.self.hello # HEY
    perSystem.self.ipaddr # where you at?
    perSystem.self.sv # wrapper for systemctl/journalctl
    rclone # sync webdav and other remote stores
    sysz # systemctl tui
    wget # download the internet
  ];

  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.direnv.enable = true;
  programs.fastfetch.enable = true;
  programs.fish.enable = true; # shell
  programs.fzf.enable = true;
  programs.git.enable = true;
  programs.lazygit.enable = true;
  programs.less.enable = true;
  programs.lesspipe.enable = true;
  programs.lsd.enable = true;
  programs.micro.enable = true; # easy text editor
  programs.neovim.enable = false; # using nvf instead
  programs.nnn.enable = true;
  programs.ripgrep.enable = true;
  programs.tealdeer.enable = true;
  programs.yazi.enable = true; # browse muh filez
  programs.yt-dlp.enable = true; # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
  programs.zoxide.enable = true;
  programs.zsh.enable = true; # shell
  services.mpd.enable = true; # play pretty music plz
  services.syncthing.enable = true; # sync muh stuff

  # Precious memories
  home.stateVersion = "24.11";
}
