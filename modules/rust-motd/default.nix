# programs.rust-motd.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.programs.rust-motd;
  inherit (lib) ls;

in {

  # Slightly modified from nixpkgs to add assertion that users.motd == null or ""
  imports = ls ./.; 
  disabledModules = [ "programs/rust-motd.nix" ];

}
