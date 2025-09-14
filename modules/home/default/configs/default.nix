{
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;

  # List packages installed in user profile
  home.packages = [
    perSystem.nix-ai-tools.crush # ai coding agent
    perSystem.self.ipaddr # where you at?
    perSystem.self.sv # wrapper for systemctl/journalctl
    pkgs._1password-cli # op
    # pkgs.calcure # calendar viewer
    # pkgs.distrobox pkgs.distrobox-tui
    pkgs.imagemagick # animate compare composite conjure convert display identify import magick magick-script mogrify montage stream
    pkgs.killall # kill by process name
    pkgs.lame # mp3 codec
    pkgs.lazydocker # docker tui
    pkgs.lf
    pkgs.linode-cli # control linode virtual servers
    pkgs.lsd
    pkgs.mosh # ssh despite bad networks
    pkgs.nano # text editor
    pkgs.ncdu # recover available disk space
    pkgs.parted # manage disks
    pkgs.rclone # sync webdav and other remote stores
    pkgs.sysz # systemctl tui
  ];

  programs.bat.enable = lib.mkDefault true;
  programs.btop.enable = lib.mkDefault true;
  programs.direnv.enable = lib.mkDefault true;
  programs.fastfetch.enable = lib.mkDefault true;
  programs.fish.enable = lib.mkDefault true; # shell
  programs.fzf.enable = lib.mkDefault true;
  programs.git.enable = lib.mkDefault true;
  programs.lazygit.enable = lib.mkDefault true;
  programs.less.enable = lib.mkDefault true;
  programs.lesspipe.enable = lib.mkDefault true;
  programs.lsd.enable = lib.mkDefault true;
  programs.micro.enable = lib.mkDefault true; # easy text editor
  programs.neovim.enable = lib.mkDefault false; # using nvf instead
  programs.nnn.enable = lib.mkDefault true;
  programs.ripgrep.enable = lib.mkDefault true;
  programs.tealdeer.enable = lib.mkDefault true;
  programs.tmux.enable = lib.mkDefault true;
  programs.yazi.enable = lib.mkDefault true; # browse muh filez
  programs.yt-dlp.enable = lib.mkDefault true; # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
  programs.zoxide.enable = lib.mkDefault true;
  programs.zsh.enable = lib.mkDefault true; # shell
}
