# modules.ollama.enable = true;
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.modules.ollama;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (config.age) secrets;
  inherit (config.modules) traefik;
  inherit (this.lib) destabilize;

  # https://github.com/open-webui/open-webui/pkgs/container/open-webui
  version = "main";

in {

  imports = 

    # Unstable upstream nixos module
    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/misc/ollama.nix
    ( destabilize inputs.nixpkgs-unstable "services/misc/ollama.nix" );

  options.modules.ollama = {
    enable = lib.options.mkEnableOption "ollama"; 
    name = mkOption {
      type = types.str; 
      default = "ollama";
    };
    port = mkOption {
      type = types.port;
      default = 11434; 
    };
    webPort = mkOption {
      type = types.port;
      default = 8080; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/ollama"; 
    };
  };

  config = mkIf cfg.enable {

    # Ensure data directory exists with expected ownership
    file."${cfg.dataDir}/webui" = { 
      type = "dir"; 
      mode = 775; 
      user = "ollama";
      group = "ollama";
    };

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      listenAddress = "0.0.0.0:${toString cfg.port}";
    };

    virtualisation.oci-containers.containers.open-webui = {
      image = "ghcr.io/open-webui/open-webui:${version}";

      # Map volumes to host
      volumes = [ 
        "${cfg.dataDir}/webui:/app/backend/data"
      ];

      # Env variables
      environmentFiles = [ 
        "${cfg.dataDir}/webui-env"
      ];

      # Traefik labels
      extraOptions = traefik.labels [ cfg.name cfg.webPort ]

      # Networking
      ++ [ "--add-host=host.docker.internal:host-gateway" ];

    };

    # Run this activation script AFTER etc & agenix
    system.activationScripts."open-webui" = lib.stringAfter [ "etc" "agenix" ] ''
      echo "WEBUI_SECRET_KEY=$(cat ${secrets.alphanumeric-secret.path})" > ${cfg.dataDir}/webui-env
    '';

    # Open up the firewall for ollama
    networking.firewall.allowedTCPPorts = [ cfg.port ];

  };

}
