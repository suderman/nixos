{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.desktop-theme;
  pair = osConfig.programs.stylix-theme-toggle;
  names = map (n: "base${n}") ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F"];
  state = "${config.xdg.stateHome}/desktop-theme";
  scheme = mode: (config.stylix.base16.mkSchemeAttrs pair."${mode}Scheme").override config.stylix.override;
  qtAssets = import ./qt-assets.nix {inherit config lib pkgs;};
  theme = mode: let
    colors = scheme mode;
    gtkCss = colors {
      template = builtins.readFile "${config.stylix.inputs.self}/modules/gtk/gtk.css.mustache";
      extension = ".css";
    };
  in
    pkgs.linkFarm "desktop-theme-${mode}" [
      {
        name = "qt";
        path = qtAssets mode colors;
      }
      {
        name = "mode";
        path = pkgs.writeText "appearance-mode" mode;
      }
      {
        name = "palette.lua";
        path = pkgs.writeText "appearance-palette.lua" "return ${lib.generators.toLua {} (lib.genAttrs names (n: colors.${n}))}";
      }
      {
        name = "kitty.conf";
        path = colors {
          templateRepo = config.stylix.inputs.tinted-kitty;
          target = "base16";
        };
      }
      {
        name = "gtk.css";
        path = pkgs.writeText "appearance-gtk.css" ''
          @import url("${gtkCss}");
          ${config.stylix.targets.gtk.extraCss}
        '';
      }
      {
        name = "waybar.css";
        path = pkgs.writeText "appearance-waybar.css" (lib.concatMapStringsSep "\n" (n: "@define-color ${n} #${colors.${n}};") names);
      }
      {
        name = "rofi.rasi";
        path = pkgs.writeText "appearance-rofi.rasi" ''
          * {
            bg0: #${colors.base00}F2;
            bg1: #${colors.base02}80;
            bg2: #${colors.base0D};
            fg0: #${colors.base05};
            fg1: #${colors.base06};
            fg2: #${colors.base00};
            fg3: #${colors.base04};
          }
        '';
      }
      {
        name = "mako.conf";
        path = pkgs.writeText "appearance-mako.conf" ''
          background-color=#${colors.base00}
          text-color=#${colors.base05}
          border-color=#${colors.base0D}
          progress-color=over #${colors.base02}
        '';
      }
    ];
  assets = pkgs.linkFarm "desktop-theme-assets" (map (mode: {
    name = mode;
    path = theme mode;
  }) ["dark" "light"]);
  gtkThemes = pkgs.runCommand "desktop-gtk-themes" {} ''
    mkdir -p "$out/share/themes"
    ${lib.concatMapStringsSep "\n" (mode: ''
      cp -rL ${pkgs.adw-gtk3}/share/themes/adw-gtk3${lib.optionalString (mode == "dark") "-dark"} "$out/share/themes/desktop-${mode}"
      chmod -R u+w "$out/share/themes/desktop-${mode}"
      cat ${assets}/${mode}/gtk.css >> "$out/share/themes/desktop-${mode}/gtk-3.0/gtk.css"
    '') ["dark" "light"]}
  '';
  command = pkgs.writeShellApplication {
    name = "desktop-theme";
    runtimeInputs = with pkgs; [coreutils util-linux dconf glib procps mako];
    text =
      lib.replaceStrings ["@assets@" "@default@" "@lightIcons@" "@darkIcons@"]
      ["${assets}" cfg.defaultMode (lib.escapeShellArg config.stylix.icons.light) (lib.escapeShellArg config.stylix.icons.dark)]
      (builtins.readFile ./switch.sh);
  };
in {
  options.programs.desktop-theme = {
    enable = lib.mkEnableOption "prepared user-session light and dark themes";
    defaultMode = lib.mkOption {
      type = lib.types.enum ["dark" "light"];
      default =
        if config.stylix.polarity == "light"
        then "light"
        else "dark";
      description = "Initial appearance when this user has not selected a mode.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      default = command;
    };
    assets = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      default = assets;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.stylix.enable && pair.enable;
        message = "desktop-theme requires Stylix and the configured dark/light scheme pair.";
      }
      {
        assertion = config.qt.enable && config.qt.platformTheme.name == "qtct" && config.qt.style.name == "kvantum";
        message = "desktop-theme Qt integration requires the qtct platform and Kvantum style.";
      }
    ];
    home.packages = [command];
    persist.storage.directories = [".local/state/desktop-theme"];
    # This state is separate from editable config copies under ~/.local/store.
    home.activation.desktopTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${lib.getExe command} prepare
    '';
    home.activation.desktopThemeRefresh = lib.hm.dag.entryAfter ["stylixLookAndFeel" "reloadSystemd"] ''
      if ${pkgs.systemd}/bin/systemctl --user --quiet is-active ${config.wayland.systemd.target}; then
        run ${pkgs.systemd}/bin/systemctl --user start desktop-theme.service
      fi
    '';
    systemd.user.services.desktop-theme = {
      Unit = {
        Description = "Apply the selected desktop appearance";
        After = ["graphical-session-pre.target"];
        PartOf = [config.wayland.systemd.target];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe command} apply";
      };
      Install.WantedBy = [config.wayland.systemd.target];
    };

    # GTK3 reloads named themes, but caches user CSS. Keep colors in the named
    # themes instead. GTK4 reads the selected CSS when an application starts.
    stylix.targets.gtk.flatpakSupport.enable = false;
    gtk.theme = {
      name = lib.mkForce "desktop-${cfg.defaultMode}";
      package = lib.mkForce gtkThemes;
    };
    xdg.configFile."gtk-3.0/gtk.css".source = lib.mkForce (pkgs.writeText "desktop-gtk3-user.css" "");
    xdg.configFile."gtk-4.0/gtk.css".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${state}/current/gtk.css");
    xdg.configFile."kitty/light-theme.auto.conf" = lib.mkIf config.programs.kitty.enable {source = "${assets}/light/kitty.conf";};
    xdg.configFile."kitty/dark-theme.auto.conf" = lib.mkIf config.programs.kitty.enable {source = "${assets}/dark/kitty.conf";};
    # Kitty initially reports no preference in this Hyprland session. Use the
    # selected mode until the portal sends its first appearance event.
    xdg.configFile."kitty/no-preference-theme.auto.conf" = lib.mkIf config.programs.kitty.enable {
      source = config.lib.file.mkOutOfStoreSymlink "${state}/current/kitty.conf";
    };
    # Keep Stylix's Qt fonts and packages. Runtime owns the active color files.
    qt.kvantum.themes = lib.mkForce [
      (pkgs.linkFarm "desktop-kvantum-themes" (map (mode: {
        name = "share/Kvantum/Desktop-${mode}";
        path = "${assets}/${mode}/qt/Kvantum/Desktop-${mode}";
      }) ["dark" "light"]))
    ];
    xdg.configFile."Kvantum/kvantum.kvconfig".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${state}/current/qt/kvantum.kvconfig");
    xdg.configFile."qt5ct/qt5ct.conf".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${state}/current/qt/qt5ct.conf");
    xdg.configFile."qt6ct/qt6ct.conf".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${state}/current/qt/qt6ct.conf");

    # Only select the Settings backend. Screencast and file chooser stay intact.
    xdg.configFile."xdg-desktop-portal/portals.conf".text = lib.generators.toINI {} {
      preferred = {
        default = "*";
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };
    };
  };
}
