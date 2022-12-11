{ inputs, config, pkgs, lib, ... }: {

  imports = [ ../.
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework
  ] ++ [
    ../keyd.nix
    ../wayland.nix
    ../gnome.nix
    ../vim.nix

    ../traefik.nix
    ../owncloud-ocis.nix
    ../whoogle.nix
    ../whoami.nix

  ];


  services.whoogle.enable = true;
  services.whoami.enable = true;

  # services.nextdns = {
  #   enable = true;
  #   # arguments = [ "-config" "e46da3" "-listen" "0.0.0.0:53" ];
  #   arguments = [ "-config" "10.0.3.0/24=e46da3" "-cache-size" "10MB" ];
  # };
  # environment.systemPackages = with pkgs; [ nextdns ];
  # networking = {
  #   firewall.allowedTCPPorts = [ 53 ];
  #   firewall.allowedUDPPorts = [ 53 ];
  #   nameservers = [ "45.90.28.239" "45.90.30.239" ];
  # };

  # services.dnsmasq.enable = true;
  # services.dnsmasq.extraConfig = ''
  #   address=/.local.lan/127.0.0.1
  #   address=/.cog.lan/100.113.50.123
  #   address=/.lux.lan/100.103.189.54
  #   address=/.graphene.lan/100.101.42.9
  # '';

  # services.sabnzbd.enable = true;
  # services.sabnzbd.user = "me";
  # services.sabnzbd.group = "users";

  # https://search.nixos.org/options?show=services.tandoor-recipes.enable&query=services.tandoor-recipes
  services.tandoor-recipes.enable = true;
  services.tandoor-recipes.port = 8081;

  # https://search.nixos.org/options?show=services.gitea.enable&query=services.gitea
  services.gitea.enable = true;
  services.gitea.database.type = "mysql";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable sound.
  sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Packages
  # environment.systemPackages = with pkgs; [];

  # Other
  # programs.nix-ld.enable = true;

}
