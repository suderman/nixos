{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) makeOverridable mkOption types;
  inherit (pkgs) fetchurl;
  inherit (pkgs.stdenv) mkDerivation;

  # https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/default.nix
  buildFirefoxXpiAddon = makeOverridable ({
    pname,
    version,
    addonId,
    url,
    sha256,
    meta,
    ...
  }:
    mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl {inherit url sha256;};

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = {inherit addonId;};

      # buildCommand = ''
      #   dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
      #   mkdir -p "$dst"
      #   install -v -m644 "$src" "$dst/${addonId}.xpi"
      # '';
      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${pname}@extraAddons.xpi"
      '';
    });
in {
  options.programs.firefox = {
    extraAddons = mkOption {
      type = types.anything;
      default = {};
    };
  };

  # To get details, install via firefox and check this URL:
  # about:debugging#/runtime/this-firefox
  config.programs.firefox.extraAddons = {
    # https://addons.mozilla.org/en-US/firefox/addon/easy-container-shortcuts/
    "easy-container-shortcuts" = buildFirefoxXpiAddon {
      pname = "easy-container-shortcuts";
      version = "1.6.0";
      # addonId = "{e52552b9-5280-4698-b818-257818153f8f}";
      addonId = "easy-container-shortcuts@extraAddons";
      url = "https://addons.mozilla.org/firefox/downloads/file/4068015/easy_container_shortcuts-1.6.0.xpi";
      # sha256 = "sha256-B5MwcMObKuihMTyCGwd6QgX/RrYS5THfZbUosMMH9gc=";
      sha256 = "01zn0z1v0a5mcpgk3r8jnr3gy1a2g83ip0iw66hyhalvqdq314q7";
      meta = with lib; {
        description = "Easy, opinionated, keyboard shortcuts for Firefox 57+ containers.";
        license = licenses.bsd2;
        mozPermissions = ["tabs" "contextualIdentities" "cookies"];
        platforms = platforms.all;
      };
    };
  };
}
