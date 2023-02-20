# secrets.enable = true;
{ inputs, config, pkgs, lib, ... }:

let 
  cfg = config.secrets;

in {

  # Import agenix module
  imports = [ inputs.agenix.nixosModules.default ];

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [

      # Include agenix command
      inputs.agenix.packages."${pkgs.stdenv.system}".default

      # Add secrets scripts to bin path
      ( pkgs.writeShellScriptBin "secrets" "/etc/nixos/secrets/scripts/secrets $@" )
      ( pkgs.writeShellScriptBin "secrets-keyscan" "/etc/nixos/secrets/scripts/secrets-keyscan $@" )
      ( pkgs.writeShellScriptBin "secrets-rekey" "/etc/nixos/secrets/scripts/secrets-rekey $@" )

    ];

  };

}
