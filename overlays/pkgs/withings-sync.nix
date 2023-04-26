{ lib, writeShellApplication, docker }: (writeShellApplication {
  name = "withings-sync";
  runtimeInputs = [ docker ];

  text = let img = "ghcr.io/jaroslawhartman/withings-sync:master"; in ''
    docker run -v "$HOME:/root" -e GARMIN_USERNAME -e GARMIN_PASSWORD -it --rm --name withings ${img} "$@"
  '';

}) // {
  meta = with lib; {
    description = "withings-sync";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
