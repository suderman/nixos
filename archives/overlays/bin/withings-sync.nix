# RETIRED - now using python package provided in nixpkgs
# https://github.com/jaroslawhartman/withings-sync
{ lib, this, docker }: let

  # https://github.com/jaroslawhartman/withings-sync/pkgs/container/withings-sync
  image = "ghcr.io/jaroslawhartman/withings-sync";
  tag = "v4.2.7";

in this.lib.mkShellScript {

  name = "withings-sync";
  inputs = [ docker ];

  text = let command = 
    ''--name withings --rm --dns 8.8.8.8 '' +
    ''-e GARMIN_USERNAME -e GARMIN_PASSWORD '' +
    ''-v $HOME:/root '' +
    ''${image}:${tag}'';

  in ''
    if [[ -v NONINTERACTIVE ]]; then
      docker run ${command} "$@"
    else
      docker run -it ${command} "$@"
    fi
  '';

}
