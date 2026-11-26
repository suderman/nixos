{config, ...}: {
  # Jon's layout, so paths match his: org, media, and profile arrive from his
  # devices through Syncthing.
  home.directories = rec {
    DOCUMENTS = {
      path = "${PROFILE.path}/apps/documents";
      sync = false;
      enable = true;
    };
    DOWNLOAD = {
      path = "inbox";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    MUSIC = {
      path = "${MEDIA.path}/music";
      sync = false;
      enable = true;
    };
    PICTURES = {
      path = "${MEDIA.path}/images";
      sync = false;
      enable = true;
    };
    PROJECTS = {
      path = "${ORG.path}/work";
      sync = false;
      enable = true;
    };
    VIDEOS = {
      path = "${MEDIA.path}/videos";
      sync = false;
      enable = true;
    };

    DESKTOP.enable = false;
    PUBLICSHARE.enable = false;
    TEMPLATES.enable = false;

    # A copy of Jon's media, already backed up from his hosts.
    MEDIA = {
      path = "media";
      persist = "scratch";
      sync = true;
      enable = true;
    };
    ORG = {
      path = "org";
      persist = "storage";
      sync = true;
      enable = true;
    };
    PROFILE = {
      path = "profile";
      persist = "storage";
      sync = true;
      enable = true;
    };
    SOURCE = {
      path = "src";
      persist = "storage";
      sync = false;
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    "${config.home.homeDirectory}/${config.home.directories.SOURCE.path}"
  ];

  # Jon's always-on Syncthing devices
  services.syncthing.deviceIds = {
    kit = "ARS5AY4-HVAKVHE-5IIYPX5-DZORQBR-UHYYQIQ-ON7JMUI-2PPI5IS-EW3IKAZ";
    cog = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY";
    lux = "SZAA6CG-YRKTOWY-QLMU4LA-33VPG47-UQNVEMS-SS3TPGA-26KBCLS-WSJYDQU";
  };
}
