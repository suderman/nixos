{
  lib,
  pkgs,
  flake,
  ...
}: {
  # Import all *.nix files in this directory and options directory
  imports = flake.lib.ls ./. ++ flake.lib.ls ../options;

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
  programs.mosh.enable = lib.mkDefault true;
  programs.rust-motd.enable = lib.mkDefault true;
  services.blocky.enable = lib.mkDefault true;
  services.earlyoom.enable = lib.mkDefault true;
  services.keyd.enable = lib.mkDefault true;
  services.tailscale.enable = lib.mkDefault true;
  services.traefik.enable = lib.mkDefault true;
  services.whoami.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;
  virtualisation.docker.enable = lib.mkDefault true;

  # Precious memories
  system.stateVersion = "24.11";
}
