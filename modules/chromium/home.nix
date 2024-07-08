# programs.chromium.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) ls mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "chromium-browser";

in {

  imports = ls ./.;

  config = mkIf cfg.enable {

    programs.chromium = {
      commandLineArgs = [ "--enable-features=WebUIDarkMode" ];
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      extensions = [{ 
        id = "dcpihecpambacapedldabdbpakmachpb"; # Bypass Paywalls
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml"; 
      }] ++ map (id: { inherit id; }) [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # UBlock Origin
        "jpbjcnkcffbooppibceonlgknpkniiff" # Global Speed
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "dhdgffkkebhmkfjojejmpbldmpobfkfo" # TamperMonkey
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        "icallnadddjmdinamnolclfjanhfoafe" # FastForward
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
        "gfbliohnnapiefjpjlpjnehglfpaknnc" # Surfingkeys
        "cnojnbdhbhnkbcieeekonklommdnndci" # Search by Image
        "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for Github
        "padekgcemlokbadohgkifijomclgjgif" # Proxy SwitchyOmega
      ];
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "alt.f" = "C-f"; # find in page
      "super.[" = "C-S-tab"; # prev tab
      "super.]" = "macro(C-tab)"; # next tab
      "super.w" = "C-w"; # close tab
      "super.t" = "C-t"; # new tab
    };

    # tag Chromium and Picture-in-Picture windows
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tag +web2, class:(${class})"
        "tag +pip, title:^(Picture in picture)$"
      ];
    };

    xdg.configFile = let flags = ''
      --enable-features=UseOzonePlatform 
      --ozone-platform=wayland
      '';
    in {
      "chromium-flags.conf".text = flags;
      "electron-flags.conf".text = flags;
      "electron-flags16.conf".text = flags;
      "electron-flags17.conf".text = flags;
      "electron-flags18.conf".text = flags;
      "electron-flags19.conf".text = flags;
      "electron-flags20.conf".text = flags;
      "electron-flags21.conf".text = flags;
      "electron-flags22.conf".text = flags;
      "electron-flags23.conf".text = flags;
      "electron-flags24.conf".text = flags;
      "electron-flags25.conf".text = flags;
    };

  };

}
