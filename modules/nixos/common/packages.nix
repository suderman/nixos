{
  config,
  pkgs,
  perSystem,
  ...
}: {
  # ---------------------------------------------------------------------------
  # System Enviroment & Packages
  # ---------------------------------------------------------------------------
  environment = {
    # List packages installed in system profile
    systemPackages = with pkgs; [
      arp-scan
      bash-completion
      btop
      cachix # binary cache
      curl
      dig
      git # basics
      gnumake
      home-manager # include home-manager command
      htop
      inetutils
      jq
      lsof
      mtr
      nix-bash-completions
      nix-zsh-completions
      nmap
      pciutils
      rsync
      sysstat
      tmux
      unzip
      usbutils
      vim
      zip
      zsh-completions
    ];

    # Add terminfo files
    enableAllTerminfo = true;
  };
}
