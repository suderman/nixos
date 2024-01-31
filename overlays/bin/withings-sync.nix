# https://github.com/jaroslawhartman/withings-sync
{ lib, this, docker }: let

  # https://github.com/jaroslawhartman/withings-sync/pkgs/container/withings-sync
  image = "ghcr.io/jaroslawhartman/withings-sync";
  tag = "v4.2.1";

in this.lib.mkShellScript {

  name = "withings-sync";
  inputs = [ docker ];

  text = let command = 
    ''--name withings --rm '' +
    ''-e GARMIN_USERNAME -e GARMIN_PASSWORD '' +
    ''-v "/home/${builtins.head this.admins}:/root" '' +
    ''${image}:${tag}'';

  in ''
    if [[ -v NONINTERACTIVE ]]; then
      docker run ${command} "$@"
    else
      docker run -it ${command} "$@"
    fi
  '';

}
