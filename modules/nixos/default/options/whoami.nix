# services.whoami.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.whoami;
  inherit (lib) mkIf mkOption types mkDefault recursiveUpdate;
  inherit (config.services.traefik.lib) mkLabels;
in {
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/web-apps/whoami.nix
  disabledModules = ["services/web-apps/whoami.nix"];

  options.services.whoami = {
    enable = lib.options.mkEnableOption "whoami";
    name = mkOption {
      type = types.str;
      default = "whoami";
    };
  };

  config = mkIf cfg.enable {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Configure OCI container
    virtualisation.oci-containers.containers."whoami" = {
      image = "traefik/whoami";
      cmd = ["--port=2001"];
      extraOptions =
        mkLabels [cfg.name 2001]
        ++ ["--network=host"];
    };
  };
}
