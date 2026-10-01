{
  config,
  lib,
  pkgs,
}: mode: colors: let
  # QPalette roles 0..20, shared by Qt5 and Qt6. qt6ct derives Accent from Highlight.
  roles = ["05" "01" "06" "04" "03" "02" "05" "07" "05" "00" "00" "02" "0D" "00" "0D" "0E" "01" "00" "00" "05" "04"];
  palette = disabled: lib.concatStringsSep ", " (lib.imap0 (index: role: "#${colors.${
    "base${
      if disabled && builtins.elem index [0 6 8 19]
      then "04"
      else role
    }"
  }}") roles);
  format = pkgs.formats.ini {listToValue = values: lib.concatStringsSep ", " values;};
  paletteFile = format.generate "desktop-qt-palette-${mode}.conf" {
    ColorScheme = {
      active_colors = palette false;
      inactive_colors = palette false;
      disabled_colors = palette true;
    };
  };
  ct = version:
    format.generate "desktop-qt${version}ct-${mode}.conf" (config.qt."qt${version}ctSettings"
      // {
        Appearance =
          config.qt."qt${version}ctSettings".Appearance
          // {
            color_scheme_path = "${paletteFile}";
            icon_theme = config.stylix.icons.${mode};
          };
      });
  render = file: extension:
    colors {
      template = builtins.replaceStrings ["base0E"] ["base0D"] (builtins.readFile "${config.stylix.inputs.self}/modules/qt/${file}");
      inherit extension;
    };
in
  pkgs.linkFarm "desktop-qt-${mode}" [
    {
      name = "qt5ct.conf";
      path = ct "5";
    }
    {
      name = "qt6ct.conf";
      path = ct "6";
    }
    {
      name = "palette.conf";
      path = paletteFile;
    }
    {
      name = "kvantum.kvconfig";
      path = format.generate "desktop-kvantum-${mode}.kvconfig" (config.qt.kvantum.settings
        // {
          General = config.qt.kvantum.settings.General // {theme = "Desktop-${mode}";};
        });
    }
    {
      name = "Kvantum/Desktop-${mode}/Desktop-${mode}.kvconfig";
      path = render "kvconfig.mustache" ".kvconfig";
    }
    {
      name = "Kvantum/Desktop-${mode}/Desktop-${mode}.svg";
      path = render "kvantum.svg.mustache" ".svg";
    }
  ]
