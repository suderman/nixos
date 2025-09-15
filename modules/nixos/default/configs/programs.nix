{
  lib,
  pkgs,
  ...
}: {
  # List packages installed in system profile
  environment.systemPackages = [
    pkgs.arp-scan
    pkgs.bash-completion
    pkgs.btop
    pkgs.cachix # binary cache
    pkgs.curl
    pkgs.dig
    pkgs.git
    pkgs.gnumake
    pkgs.home-manager
    pkgs.htop
    pkgs.inetutils
    pkgs.jq
    pkgs.lsof
    pkgs.mtr
    pkgs.nix-bash-completions
    pkgs.nix-zsh-completions
    pkgs.nmap
    pkgs.pciutils
    pkgs.rsync
    pkgs.sysstat
    pkgs.tmux
    pkgs.unzip
    pkgs.usbutils
    pkgs.zip
    pkgs.zsh-completions
  ];

  # Default enable these common modules for all hosts
  programs.mosh.enable = lib.mkDefault true;
  programs.rust-motd.enable = lib.mkDefault true;
}
