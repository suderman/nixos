# packages/pgvecto-rs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
# (tweaked by Jon Suderman Feb 23 2024)
#
# A PostgreSQL extension needed for Immich.
# This builds from the pre-compiled binary instead of from source.
# https://github.com/diogotcorreia/dotfiles/blob/nixos/packages/pgvecto-rs.nix

{ lib, system, stdenv, fetchurl, dpkg, postgresql }:

let

  # https://github.com/tensorchord/pgvecto.rs/releases/
  version = "0.2.0";

  # > nix hash file vectors-pg*.deb
  versionHashes = {
    pg14_amd64 = "sha256-8RDWkVbSxAmhSlggbYeSXHvCg5TNavvIPIZ0Ivua61Q="; 
    pg14_arm64 = "sha256-X+KYo2C4evSRujQXxhHcrgfVKKjjcFBIg1GpACUimPk=";
    pg15_amd64 = "sha256-uPE76ofzAevJMHSjFHYJQWUh5NZotaD9dhaX84uDFiQ="; 
    pg15_arm64 = "sha256-G+0I714DmZNvrbc8f+RqEY8edKogHUd2R87HBmp0FAk=";
    pg16_amd64 = "sha256-aJ1wLNZVdsZAvQeE26YVnJBr8lAm6i6/3eio5H44d7s="; 
    pg16_arm64 = "sha256-hKUWr3sCaObfGFod3I33YoJ0AO9sMyAxFIA6tJ++0cw=";
  };

  major = lib.versions.major postgresql.version;
  arch = if system == "aarch64-linux" then "arm64" else "amd64";

in stdenv.mkDerivation rec {

  pname = "pgvecto-rs";
  inherit version;

  buildInputs = [ dpkg ];

  # For example:
  # https://github.com/tensorchord/pgvecto.rs/releases/download/v0.2.0/vectors-pg14_0.2.0_amd64.deb
  # https://github.com/tensorchord/pgvecto.rs/releases/download/v0.2.0/vectors-pg14_0.2.0_arm64.deb
  src = fetchurl {
    url = "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}_${version}_${arch}.deb";
    hash = versionHashes."pg${major}_${arch}";
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
    rm -rf $out/usr
  '';

  meta = with lib; {
    description =
      "pgvecto.rs extension for PostgreSQL: Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
    homepage = "https://github.com/tensorchord/pgvecto.rs";
  };
}
