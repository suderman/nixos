{ lib, config, pkgs, ... }: {
  home.packages = [
    pkgs.nsxiv

    # (pkgs.gimp-with-plugins.override {
    #   plugins = [
    #     pkgs.gimpPlugins.gmic
    #     pkgs.gimpPlugins.lqrPlugin
    #     pkgs.gimpPlugins.texturize
    #     pkgs.gimpPlugins.resynthesizer
    #     pkgs.gimpPlugins.waveletSharpen
    #   ];
    # })

    pkgs.inkscape

    pkgs.darktable
  ];

  # home.persistence."/persist${config.home.homeDirectory}".directories = [
  #   "pictures"
  #   "etc/GIMP"
  # ];
  #
  # xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
  #
  # xdg.mimeApps = {
  #   defaultApplications = {
  #     "image/x-dcraw" = "darktable.desktop";
  #     "image/tiff" = "darktable.desktop";
  #     "image/svg+xml" = [ "inkscape.desktop" "nsxiv.desktop" "gimp.desktop" ];
  #   } // (
  #     lib.genAttrs [
  #       "image/avif"
  #       "image/bmp"
  #       "image/gif"
  #       "image/heif"
  #       "image/jp2"
  #       "image/jpeg"
  #       "image/jxl"
  #       "image/png"
  #       "image/webp"
  #       "image/x-portable-anymap"
  #       "image/x-portable-bitmap"
  #       "image/x-portable-graymap"
  #       "image/x-tga"
  #       "image/x-xpixmap"
  #     ]
  #       (_: [ "nsxiv.desktop" ])
  #   );
  #
  #   associations.removed = lib.genAttrs [ "image/jpeg" "image/png" "image/tiff" ] (_: "darktable.desktop");
  # };
}
