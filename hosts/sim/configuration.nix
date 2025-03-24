{ config, flake, pkgs, lib, ... }: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
in {

  imports = [
    flake.nixosModules.common
    flake.nixosModules.vm
    flake.nixosModules.homelab
  ];
  # ] ++ flake.lib.ls ./.;

  config = {

    path = ./.;
    stable = false;
    
    networking.domain = "tail";

    # host.domain = "tail";

    # host = import ./host.nix;
    # nixpkgs.hostPlatform = "x86_64-linux";

    environment.systemPackages = [
      pkgs.vim
    ];

    age.secrets.foo.rekeyFile = ./foo.txt.age; 
    environment.etc = {
      "foo.txt" = {
        source = config.age.secrets.foo.path;
        mode = "0750";
        user = "jon";
        group = "users";
      };
    };

    # users.users.root = {
    #   initialPassword = "root";
    # };

    # Disallow modifying users outside of this config
    users.mutableUsers = false;

    users.users.jon = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.bash;
      uid = 1000;
      initialPassword = "jon";
      group = "users";
      extraGroups = [ "wheel" "input" ];
      linger = true;
    };

    users.groups.users = {};

    # networking.hostName = "sim";
    # networking.hostPubkey = ./ssh_host_ed25519_key.pub;
    # networking.hostPrvkey = ./ssh_host_ed25519_key.age;
    networking.firewall.allowPing = true;

    # test.foo = config.age.secrets.foo.path;

    services.tailscale.enable = true;
    services.openssh.enable = true;

    # system.stateVersion = "24.11";

    # test.hostName = builtins.baseNameOf ./.;

  };
}
