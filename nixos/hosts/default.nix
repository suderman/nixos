{ inputs, config, lib, pkgs, username, hostname, domain, ... }: 

with builtins;

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

in {

  # ---------------------------------------------------------------------------
  # COMMON CONFIGURATION FOR ALL NIXOS HOSTS
  # ---------------------------------------------------------------------------
  imports = [ ../. ];


  # Set your time zone.
  time.timeZone = "America/Edmonton";


  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  # Hostname passed as argument from flake
  networking.hostName = hostname; 
  networking.domain = domain;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };


  # ---------------------------------------------------------------------------
  # System Enviroment & Packages
  # ---------------------------------------------------------------------------
  environment = {

    # List packages installed in system profile
    systemPackages = with pkgs; [ 
      inetutils mtr sysstat gnumake git # basics
      inputs.agenix.defaultPackage."${stdenv.system}" # include agenix command
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


  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  users = {
    users."${username}" = with pkgs; {
      isNormalUser = true;
      shell = zsh;
      home = "/home/${username}";
      description = username;
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
      ]; 
      openssh.authorizedKeys.keys = [ config.keys."${username}" ];
    };
    mutableUsers = true;
  };

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
    { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
  ];

  # Allows users to allow others on their binds
  programs.fuse.userAllowOther = true;


  # ---------------------------------------------------------------------------
  # Nix Settings
  # ---------------------------------------------------------------------------

  nix.settings = {

    # Enable flakes and new 'nix' command
    experimental-features = [ "nix-command" "flakes" "repl-flake" ];

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    trusted-users = [ "root" "@wheel" ];
    warn-dirty = false;

    # substituters = [
    #   "https://hyprland.cachix.org"
    #   "https://nix-community.cachix.org"
    # ];
    # trusted-public-keys = [
    #   "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    # ];

  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Add each flake input as a registry
  # To make nix3 commands consistent with the flake
  nix.registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

  # Map registries to channels
  # Very useful when using legacy commands
  nix.nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
