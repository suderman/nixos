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
      inetutils
      mtr
      sysstat
      gnumake
      git # basics
      curl
      btop
      htop
      tmux
      rsync
      vim
      jq
      usbutils
      pciutils
      zip
      unzip
      nmap
      arp-scan
      dig
      lsof
      nix-zsh-completions
      zsh-completions
      nix-bash-completions
      bash-completion
      home-manager # include home-manager command
      cachix # binary cache
      perSystem.neovim.default
    ];

    # Add terminfo files
    enableAllTerminfo = true;
  };
}
