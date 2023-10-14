# modules.gimp.enable = true;
{ config, pkgs, lib, ... }:

let

  cfg = config.modules.gimp;
  inherit (lib) mkIf makeBinPath;

  # https://www.gimp.org/downloads/devel/
  app = "org.gimp.GIMP";
  ref = "https://flathub.org/beta-repo/appstream/org.gimp.GIMP.flatpakref";

  flatpak = "${pkgs.flatpak}/bin/flatpak";
  ping = "${pkgs.iputils}/bin/ping";

in {

  options.modules.gimp = {
    enable = lib.options.mkEnableOption "gimp"; 
  };

  config = mkIf cfg.enable {

    home.activation.gimp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Check if GIMP has been installed via flatpak
      if [[ -z "$(${flatpak} --user --app --columns=application list | grep ${app})" ]]; then
        # Wait until network is up
        until ${ping} dl.flathub.org -c1 -q >/dev/null; do :; done
        # Install it as a user
        $DRY_RUN_CMD ${flatpak} install --user -y ${ref}
      fi
    '';

  };

}
