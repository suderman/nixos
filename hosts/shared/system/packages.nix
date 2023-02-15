{ config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # System Enviroment & Packages
  # ---------------------------------------------------------------------------
  environment = {

    # List packages installed in system profile
    systemPackages = with pkgs; [ 
      inetutils mtr sysstat gnumake git # basics
      curl htop tmux rsync vim nix-index
      usbutils pciutils zip unzip nmap arp-scan dig   
      nix-zsh-completions zsh-completions 
      nix-bash-completions bash-completion
      home-manager # include home-manager command
    ];

    # Add terminfo files
    enableAllTerminfo = true;

    # # Activate home-manager environment, if not already
    # loginShellInit = ''
    #   [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
    # '';

    # # Persist logs, timers, etc
    # persistence = {
    #   "/persist".directories = [ "/var/lib/systemd" "/var/log" "/srv" ];
    # };

  };

}
