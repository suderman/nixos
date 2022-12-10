# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, config, pkgs, lib, hostname, ... }: {

  age.secrets = {
    domain.file = ../secrets/domain.age;
    cf_dns_api_token.file = ../secrets/cf_dns_api_token.age;
  };

  imports = [
    ./nix.nix
    ./users.nix
    ./openssh.nix
    ./security.nix
    ./tailscale.nix
    ./flatpak.nix
    ./pipewire.nix
    # ./quiet-boot.nix
    # ./systemd-boot.nix
    # ./keyd.nix
    # ./wireless.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Edmonton";

  # Hostname passed as argument from flake
  networking.hostName = hostname; 
  # networking.domain = "example.com";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };

  environment = {

    # List packages installed in system profile
    systemPackages = with pkgs; [ 
      inetutils mtr sysstat gnumake git # basics
      inputs.agenix.defaultPackage."${stdenv.system}" # also include agenix command
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

  # Allows users to allow others on their binds
  programs.fuse.userAllowOther = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
