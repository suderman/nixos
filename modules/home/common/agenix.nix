{ config, flake, inputs, lib, ... }: let

  # inherit (lib.file) mkOutOfStoreSymlink;
  inherit (builtins) readFile;
  inherit (config.home) username;
  user = flake.users."${username}";

in {

  imports = [ 
    inputs.agenix.homeManagerModules.default
  ];

  # config = {
  #
  #   # age.secrets.id_ed25519.file = flake + /users/${username}/id_ed25519.age; 
  #   age.secrets.id_ed25519.file = user.openssh.privateKey; 
  #
  #
  #   home.file = with config.age.secrets; {
  #
  #     ".ssh" = { 
  #       directory = true; 
  #       mode = "700"; 
  #     };
  #
  #     ".ssh/id_ed25519" = {
  #       text = readFile id_ed25519.path;
  #       mode = "600"; 
  #     };
  #
  #     # ".ssh/id_ed25519".source = id_ed25519.path;
  #     ".ssh/id_ed25519.pub".source = flake + /users/${username}/id_ed25519.pub; 
  #
  #     # ".ssh/id_ed25519".source = mkOutOfStoreSymlink id_ed25519.path;
  #     # ".ssh/id_ed25519".text = id_ed25519.path;
  #   };
  #
  # };

}
