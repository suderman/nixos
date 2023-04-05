# base.enable = true;
{ config, lib, pkgs, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # System Enviroment & Packages
  # ---------------------------------------------------------------------------

  config = mkIf config.base.enable {

    environment = {

      # List packages installed in system profile
      systemPackages = with pkgs; [ 
        inetutils mtr sysstat gnumake git # basics
        curl htop tmux rsync vim nix-index jq
        usbutils pciutils zip unzip nmap arp-scan dig lsof 
        nix-zsh-completions zsh-completions 
        nix-bash-completions bash-completion
        home-manager # include home-manager command
        nixos-cli # found in overlays
        cachix # binary cache
      ];

      # Add terminfo files
      enableAllTerminfo = true;

    };

  };

}
