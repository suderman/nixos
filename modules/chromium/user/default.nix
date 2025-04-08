# -- modified module --
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
      # commandLineArgs = [ "--enable-features=WebUIDarkMode" ];
      commandLineArgs = [ 
        "--ozone-platform=wayland"
        "--enable-features=UseOzonePlatform,WebUIDarkMode,WaylandWindowDecorations,WebRTCPipeWireCapturer,WaylandDrmSyncobj"
        "--enable-accelerated-video-decode"
        "--enable-gpu-rasterization"
        "--disk-cache-dir=/run/user/${toString config.home.uid}/chromium-cache"
        "--remove-referrers"
        "--disable-top-sites"
        "--no-default-browser-check"
      ];
      package = pkgs.ungoogled-chromium;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      extensions = [{
        id = "ocaahdebbfolfmndjeplogmgcagdmblk";
        updateUrl = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
      }] ++ [{ 
        id = "dcpihecpambacapedldabdbpakmachpb"; # Bypass Paywalls
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml"; 
      }] ++ map (id: { inherit id; }) [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        "jpbjcnkcffbooppibceonlgknpkniiff" # Global Speed
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "dhdgffkkebhmkfjojejmpbldmpobfkfo" # TamperMonkey
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        "icallnadddjmdinamnolclfjanhfoafe" # FastForward
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
        # "gfbliohnnapiefjpjlpjnehglfpaknnc" # Surfingkeys
        # "cnojnbdhbhnkbcieeekonklommdnndci" # Search by Image
        # "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for Github
        # "padekgcemlokbadohgkifijomclgjgif" # Proxy SwitchyOmega
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

    # xdg.configFile = let flags = ''
    #     --ozone-platform=wayland
    #     --enable-features=UseOzonePlatform,WebUIDarkMode,WaylandWindowDecorations,WebRTCPipeWireCapturer,WaylandDrmSyncobj
    #     --enable-accelerated-video-decode
    #     --enable-gpu-rasterization
    #     --disk-cache-dir=/run/user/${toString config.home.uid}/chromium-cache
    #   '';
    # in {
    #   "chromium-flags.conf".text = flags;
    #   "electron-flags.conf".text = flags;
    #   "electron-flags16.conf".text = flags;
    #   "electron-flags17.conf".text = flags;
    #   "electron-flags18.conf".text = flags;
    #   "electron-flags19.conf".text = flags;
    #   "electron-flags20.conf".text = flags;
    #   "electron-flags21.conf".text = flags;
    #   "electron-flags22.conf".text = flags;
    #   "electron-flags23.conf".text = flags;
    #   "electron-flags24.conf".text = flags;
    #   "electron-flags25.conf".text = flags;
    #   "electron-flags26.conf".text = flags;
    #   "electron-flags27.conf".text = flags;
    #   "electron-flags28.conf".text = flags;
    #   "electron-flags29.conf".text = flags;
    #   "electron-flags30.conf".text = flags;
    # };

  };

}
