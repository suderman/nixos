# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

#{ config, pkgs, ... }:
# { config, pkgs, lib, options, specialArgs, modulesPath, ... }:
{ inputs, pkgs, lib, ... }:

let 
  inherit (inputs.home-manager.nixosModules) home-manager;

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./unstable.nix
      # ./keyd.nix
      ../../modules/vim.nix

      # inputs.home-manager.nixosModules.home-manager {              # Home-Manager module that is used.
      home-manager {              # Home-Manager module that is used.
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # home-manager.extraSpecialArgs = { inherit user doom-emacs; };  # Pass flake variable
        home-manager.users.me = import ../../home.nix;
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

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking.hostName = "nimbus"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Set your time zone.
  time.timeZone = "America/Edmonton";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.me = {
     isNormalUser = true;
     home = "/home/me";
     description = "me";
     extraGroups = [ "wheel" "networkmanager" "docker" "input" "keyd" ]; # Enable ‘sudo’ for the user.
     openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqkkVHSFBPNT9ajrgq1lFKNhkf1QJMZgobkL8fsKlx3mle7Ug5GvW/HLymAsfP04zA1CPet4awcufEEolwY7tWfDIdCOi+8xgaJh5Te3AM9Twegc3a2CRL21Mv438LCPU03qhzHh4JPBWbatq5QxTti67joC91XiBjY/vl8aRtyUz2n/tFoS3yhfMb2qP+VU75dgWQw+WDtHbG4bT018JcL+G4wexKBM3vs51t7qdHHkcbjJh/XJ+/+WGg4SkpmzREEtL2VVh7Mn/e0jupZcU4wtsoi7652bYh1kFpi0YvlTWpdwLmhUXx1RpIYsuP/TNePoN+GBcKN+9dmJuJLJFseD8xhuYzOVpFLb/GdXWEAUlMtCdHwg1QjEUcBPTaX0CeLY/kmna1MU4SBGQ6msTDwSNUpEkKEaiv6Fx66XstAzf1g5NEauLw/YGgwDsPGgPfCraS03aJCqieHxBHe5uaD1vBA4zFvV3CBv3uvlKBUsgVbR2A1k4Bvpyw6VlasvpZhh0DoDVWNL30SvTtyVCS1sIey0GwGNYBVDBu5P5LHsCgOESKG32uHkXVEeYTdln35dJyoxP+/zMebJwNTZjGjU19ORthViwibfQMV2J931ZjkLWgVqxnn9t0hltC2845eOJ0BytX5wFxqf4IU5Ix/yuMeUwIlLocz6X6blNbsQ== me@blink" ];
  #   packages = with pkgs; [
  #     firefox
  #     thunderbird
  #   ];
  };

  users.groups.keyd.name = "keyd";


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     inetutils
     mtr
     sysstat
     gnumake
     #vim 
     #neovim
     # tmux
     wget 
     git
     zsh
     fish
     nano
     micro
     cached-nix-shell
     nerdfonts
     joypixels
     # keyd
     # unstable.keyd
   ];

  virtualisation.docker.enable = true;

  programs.nix-ld.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

