{ pkgs, lib, ... }: {

  home.packages = with pkgs; [ 
    _1password-cli
    calcure # calendar viewer
    distrobox distrobox-tui
    killall # kill by process name
    lazydocker # docker tui
    linode-cli # control linode virtual servers
    mosh # ssh despite bad networks
    nano # text editor
    ncdu # recover available disk space
    parted # manage disks
    rclone # sync webdav and other remote stores
    sv # wrapper for systemctl/journalctl
    sysz # systemctl tui
    wget # download the internet
  ];

  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.direnv.enable = true;
  programs.fastfetch.enable = true;
  programs.fzf.enable = true;
  programs.git.enable = true;
  programs.less.enable = true;
  programs.nnn.enable = true;
  programs.lesspipe.enable = true;
  programs.fish.enable = true; # shell
  programs.lsd.enable = true;
  programs.micro.enable = true; # easy text editor
  programs.neovim.enable = true; # good text editor
  programs.tealdeer.enable = true;
  programs.yazi.enable = true;
  programs.yt-dlp.enable = true; # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...
  programs.zoxide.enable = true;
  programs.zsh.enable = true; # shell
  programs.lazygit.enable = true;

  programs.ripgrep = {
    enable = true;
    package = pkgs.ripgrep-all;
    arguments = [
      "--max-columns=150"
      "--max-columns-preview"
      "--colors=line:style:bold" # pretty
      "--smart-case"
      "--hidden" # search hidden files/directories
      "--glob=!package-lock.json"
      "--glob=!node_modules/*" 
      "--glob=!.git/*"
      "--glob=!yarn.lock"
      "--glob=!.yarn/*"
      "--glob=!dist/*" 
      "--glob=!build/*"
      "--glob=!.cache/*" 
      "--glob=!.vscode/*"
    ];
  };

}
