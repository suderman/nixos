# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, hostname, config, pkgs, lib, ... }:

{

  imports = [

    # Host-specific configuration
    ./${hostname}/configuration.nix

    # Common modules
    ./shared/vim.nix

    # Home Manager
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs outputs hostname; };
      home-manager.users.me = import ./home.nix;
    }

  ];

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    settings = {

      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";

      # Deduplicate and optimize nix store
      auto-optimise-store = true;

    };
  };

  # Set your time zone.
  time.timeZone = "America/Edmonton";

  # Hostname passed as argument from flake
  networking.hostName = hostname; 

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {

    groups.keyd.name = "keyd";
    users.me = {
       isNormalUser = true;
       home = "/home/me";
       description = "me";
       extraGroups = [ "wheel" "networkmanager" "docker" "input" "keyd" ]; # Enable ‘sudo’ for the user.
       openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqkkVHSFBPNT9ajrgq1lFKNhkf1QJMZgobkL8fsKlx3mle7Ug5GvW/HLymAsfP04zA1CPet4awcufEEolwY7tWfDIdCOi+8xgaJh5Te3AM9Twegc3a2CRL21Mv438LCPU03qhzHh4JPBWbatq5QxTti67joC91XiBjY/vl8aRtyUz2n/tFoS3yhfMb2qP+VU75dgWQw+WDtHbG4bT018JcL+G4wexKBM3vs51t7qdHHkcbjJh/XJ+/+WGg4SkpmzREEtL2VVh7Mn/e0jupZcU4wtsoi7652bYh1kFpi0YvlTWpdwLmhUXx1RpIYsuP/TNePoN+GBcKN+9dmJuJLJFseD8xhuYzOVpFLb/GdXWEAUlMtCdHwg1QjEUcBPTaX0CeLY/kmna1MU4SBGQ6msTDwSNUpEkKEaiv6Fx66XstAzf1g5NEauLw/YGgwDsPGgPfCraS03aJCqieHxBHe5uaD1vBA4zFvV3CBv3uvlKBUsgVbR2A1k4Bvpyw6VlasvpZhh0DoDVWNL30SvTtyVCS1sIey0GwGNYBVDBu5P5LHsCgOESKG32uHkXVEeYTdln35dJyoxP+/zMebJwNTZjGjU19ORthViwibfQMV2J931ZjkLWgVqxnn9t0hltC2845eOJ0BytX5wFxqf4IU5Ix/yuMeUwIlLocz6X6blNbsQ== me@blink" ];
    };

  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     inetutils
     mtr
     sysstat
     gnumake
   ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
