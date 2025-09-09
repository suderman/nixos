{flake, ...}: {
  homeModules = {
    default = ./home/default;
    options = ./home/options;
    profiles = flake.lib.ls' ./home/profiles;
    users = flake.lib.ls' ./home/users;
  };
  nixosModules = {
    default = ./nixos/default;
    options = ./nixos/options;
    profiles = flake.lib.ls' ./nixos/profiles;
    hardware = flake.lib.ls' ./nixos/hardware;
    secrets = ./nixos/secrets;
  };
}
