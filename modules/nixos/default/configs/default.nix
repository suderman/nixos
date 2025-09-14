{
  lib,
  pkgs,
  flake,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = flake.lib.ls ./.;

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
    pkgs.vim
    pkgs.zip
    pkgs.zsh-completions
  ];

  # Default enable these common modules for all hosts
  programs.mosh.enable = mkDefault true;
  programs.rust-motd.enable = mkDefault true;
  services.blocky.enable = mkDefault true;
  services.earlyoom.enable = mkDefault true;
  services.keyd.enable = mkDefault true;
  services.tailscale.enable = mkDefault true;
  services.traefik.enable = mkDefault true;
  services.whoami.enable = mkDefault true;
}
