{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}: let
  sub = config.home.username;
  hostName = "${osConfig.services.attic.name}.${osConfig.networking.hostName}";
in {
  config = lib.mkIf osConfig.services.attic.enable {
    persist.storage.directories = [".config/attic"];

    home.packages = [
      (pkgs.self.mkScript {
        name = "attic-init";
        text =
          # sh
          ''
            TOKEN="$(
              cd / &&
              sudo atticd-atticadm make-token \
                --sub "${sub}" \
                --validity "120 months" \
                --pull '*' \
                --push '*' \
                --delete '*' \
                --create-cache '*' \
                --configure-cache '*' \
                --configure-cache-retention '*' \
                --destroy-cache '*'
            )"
            attic login local https://${hostName} $TOKEN --set-default
            attic cache create main
            attic cache info main
          '';
      })
    ];
  };
}
