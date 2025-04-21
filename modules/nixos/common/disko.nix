{ inputs, perSystem, pkgs, lib, ... }: let

  inherit (builtins) isString;
  inherit (lib) mkOption types;

  mnt = let mountOptions = [ # How my like my btrfs
    "compress=zstd"  # enable zstd compression
    "space_cache=v2" # track available free space on filesystem
    "discard=async"  # free up deleted space in the background
    "noatime"        # disables access time updates on files
  ]; in mountpoint: if isString mountpoint 
    then { inherit mountpoint mountOptions; } 
    else { inherit mountOptions; };

in {

  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.disko.lib = mkOption {
    type = types.anything; 
    readOnly = true; 
    default = { inherit mnt; };
  };

  config.environment.systemPackages = [ 
    perSystem.disko
    pkgs.nixos-anywhere
  ];

}
