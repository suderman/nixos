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
