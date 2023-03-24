# https://github.com/elohmeier/ptsd/blob/master/5pkgs/monica/default.nix
{ stdenv, fetchurl, storagePath ? "/var/lib/monica/storage" }:

stdenv.mkDerivation rec {
  pname = "monica";
  version = "3.7.0";

  src = fetchurl {
    url = "https://github.com/monicahq/monica/releases/download/v${version}/monica-v${version}.tar.bz2";
    sha256 = "sha256-YqGGMXRRqPnji9NoQTqX80lYaFxnANQ+WgIaYBedU+4=";
  };

  # https://github.com/ashleyhindle/monica/commit/7eeefe3484081b72a0ad20a2b788e3f514da0e18
  patches = [ ./storage-path.patch ./duplicate-carddav.patch ];

  installPhase = ''
    mkdir -p "$out/share/monica"
    cp -R . "$out/share/monica"
    ln -s "${storagePath}/app/public" "$out/share/monica/public/storage"
  '';
}
