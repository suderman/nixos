{ inputs, config, lib, pkgs, ... }: {

  imports = [ 
    ./linode-configuration.nix 
    ../shared/system 
  ];

  # Enable secrets
  secrets.enable = true;

  # Services
  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.ddns.enable = true;

  # Programs
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  services.earlyoom.enable = true;

  services.traefik.enable = true;
  services.whoami.enable = true;
  services.whoogle.enable = false;

  # # Flatpak
  # services.flatpak.enable = true;
  #
  # # SabNZBd
  # services.sabnzbd.enable = true;
  #
  # # https://search.nixos.org/options?show=services.tandoor-recipes.enable&query=services.tandoor-recipes
  # services.tandoor-recipes.enable = true;

  # https://search.nixos.org/options?show=services.gitea.enable&query=services.gitea
  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";


  # # Steam
  # programs.steam.enable = false;
  #
  # services.mysql.enable = true;
  # services.postgresql.enable = true;

  # programs._1password.enable = true;
  # programs._1password-gui.polkitPolicyOwners = [ "me" ];
  # programs._1password-gui.enable = true;

  # Packages
  # environment.systemPackages = with pkgs; [];

  # Other
  # programs.nix-ld.enable = true;

}
