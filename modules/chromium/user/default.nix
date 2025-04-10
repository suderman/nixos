# -- modified module --
# programs.chromium.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) concatStringSep hasPrefix ls mapAttrsToList mkIf versions;
  inherit (config.services.keyd.lib) mkClass;

  crxUrl = id: if hasPrefix "http://" id || hasPrefix "https://" id then id else 
    "https://clients2.google.com/service/update2/crx" +
    "?response=redirect" +
    "&acceptformat=crx2,crx3" +
    "&prodversion=${versions.major cfg.package.version}" + 
    "&x=id%3D${id}%26installsource%3Dondemand%26uc";

  extensions = {
    chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
    ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    dark-reader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
  };

  script = concatStringSep "\n" (mapAttrsToList (
    name: id: let url = crxUrl id; in ''
      curl -L "${url}" > ${name}.zip
      mkdir -p ${name}
      unzip -u ${name}.zip -d ${name}

      # curl -L "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx" > 0.zip
      # mkdir 0
      # unzip -u 0.zip -d 0
      # curl -L "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=135.0.7049.52&x=id%3Dcjpalhdlnbpafiamejdnhcphjbkeiagm%26installsource%3Dondemand%26uc" > 1.zip
      # mkdir 1
      # unzip -u 1.zip -d 1
    '' 
  ));


  # Window class name
  class = "chromium-browser";

  createSourceExtensionFor = browserVersion: { id, sha256, url, version}: {
    inherit id;
    crxPath = builtins.fetchurl {
      name = "${id}.crx";
      inherit url;
      inherit sha256;
    };
    inherit version;
  };

  createChromiumExtensionFor = browserVersion: { id, sha256, version }: {
    inherit id;
    crxPath = builtins.fetchurl {
      url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${browserVersion}&x=id%3D${id}%26installsource%3Dondemand%26uc";
      name = "${id}.crx";
      inherit sha256;
    };
    inherit version;
  };

  createSourceExtension = createSourceExtensionFor (lib.versions.major config.programs.chromium.package.version);
  createChromiumExtension = createChromiumExtensionFor (lib.versions.major config.programs.chromium.package.version);

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

        # nix-prefetch-url --name arst.crx 'https://clients2.google.com/service/...
      extensions = [
        (createSourceExtension {  # Web Store
          url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
          id = "ocaahdebbfolfmndjeplogmgcagdmblk";
          sha256 = "0ck5k4gs5cbwq1wd5i1aka5hwzlnyc4c513sv13vk9s0dlhbz4z5";
          version = "1.5.4.3";
        })
        (createChromiumExtension { # ublock origin
          id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
          sha256 = "1lnk0k8zy0w33cxpv93q1am0d7ds2na64zshvbwdnbjq8x4sw5p6";
          version = "1.61.2";
        })
        (createChromiumExtension { # dark reader
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          sha256 = "0x9l2m260y0g7l7w988sghgh8qvfghydx8pbd1gd023zkqf1nrv2";
          version = "4.9.96";
        })
      ];

      # extensions = [
      #   { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      #   {
      #     id = "qwertyuiopasdfghjklzxcvbnmqwerty";
      #     crxPath = pkgs.fetchurl {
      #       url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
      #       sha256 = "sha256-5ZO/IG1Ap7lH2HqEwgjzln4Oi5oqxNJ4wHyxoh+ZZTI";
      #     };
      #     version = "1.0";
      #   }
      # ];

      # extensions = [{
      #   id = "ocaahdebbfolfmndjeplogmgcagdmblk";
      #   updateUrl = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
      # }] ++ [{ 
      #   id = "dcpihecpambacapedldabdbpakmachpb"; # Bypass Paywalls
      #   updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/src/updates/updates.xml"; 
      # }] ++ map (id: { inherit id; }) [
      #   "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      #   "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      #   "jpbjcnkcffbooppibceonlgknpkniiff" # Global Speed
      #   "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      #   "dhdgffkkebhmkfjojejmpbldmpobfkfo" # TamperMonkey
      #   "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
      #   "icallnadddjmdinamnolclfjanhfoafe" # FastForward
      #   "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
      #   # "gfbliohnnapiefjpjlpjnehglfpaknnc" # Surfingkeys
      #   # "cnojnbdhbhnkbcieeekonklommdnndci" # Search by Image
      #   # "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for Github
      #   # "padekgcemlokbadohgkifijomclgjgif" # Proxy SwitchyOmega
      # ];
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
