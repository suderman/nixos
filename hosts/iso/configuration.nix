{ config, lib, pkgs, perSystem, modulesPath, ... }: {

  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # Set host platform and config options
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
    config.nvidia.acceptLicense = true;
  };

  # Enable flakes and larger download buffer
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 500000000; # 500MB buffer
  };

  # Name custom ISO
  networking = {
    hostName = "iso";
  };

  # Set passwords to x
  users.users = lib.genAttrs [ "root" "nixos" ] (name: {
    password = "x";
    initialHashedPassword = lib.mkForce null;
  });

  # Enable sshd
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "yes";
  };

  # Allow sshed to listen with netcat
  networking.firewall.allowedTCPPorts = [ 12345 ];

  # Start wireless 
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  # systemd.services.wpa_supplicant.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Virtualization
  services.qemuGuest.enable = true;

  # Include disko and installer script
  environment.systemPackages = [
    perSystem.disko.default
    perSystem.self.ipaddr
    perSystem.self.sshed
    pkgs.gum
    pkgs.networkmanager
    ( pkgs.writeShellScriptBin "wifi" "nmtui-connect" )
    ( pkgs.writeShellScriptBin "installer" (builtins.readFile ./installer.sh) )
  ];

  # Update /etc/issue with custom info
  services.getty.helpLine = lib.mkForce ''
    The "nixos" and "root" accounts have their passwords set to `x`.
    If you need a wireless connection, type `wifi`.
    To run installer script, type `installer`.
  '';

}
