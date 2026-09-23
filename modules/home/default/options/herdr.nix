{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr;
  package = flake.inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  tomlFormat = pkgs.formats.toml {};
  navigate = pkgs.self.mkScript {
    name = "herdr-emacs-navigate";
    path = [pkgs.jq];
    env.HERDR_NAV_HERDR =
      if cfg.package == null
      then "herdr"
      else lib.getExe cfg.package;
    text = ''
      pane="''${HERDR_ACTIVE_PANE_ID:?}"
      direction="''${1:?}"
      key="''${2:?}"
      if "$HERDR_NAV_HERDR" pane process-info --pane "$pane" 2>/dev/null \
        | jq -e 'any(.result.process_info.foreground_processes[]?.argv[0]?; test("/(emacs|emacsclient)$"))' >/dev/null; then
        exec "$HERDR_NAV_HERDR" pane send-keys "$pane" "alt+$key"
      fi
      exec "$HERDR_NAV_HERDR" pane focus --direction "$direction" --pane "$pane"
    '';
  };
in {
  # Avoid duplicate options when release-26.11 imports the upstream module.
  disabledModules = ["programs/herdr.nix"];

  # Backported from Home Manager master at 1944398834e2b9677ee6081e11e42c32d7c1eb5d.
  # Remove after moving to release-26.11.
  meta.maintainers = [lib.maintainers.amadejkastelic];

  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = mkOption {
      type = lib.types.nullOr lib.types.package;
      default = package;
      defaultText = lib.literalExpression "flake.inputs.herdr.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "The Herdr package to use.";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = {};
      example = {
        onboarding = false;
        terminal = {
          default_shell = "nu";
          shell_mode = "auto";
          new_cwd = "follow";
        };
        theme = {
          name = "catppuccin";
          auto_switch = true;
          light_name = "catppuccin-latte";
          dark_name = "catppuccin";
        };
        ui = {
          sidebar_width = 32;
          agent_panel_sort = "priority";
          toast.delivery = "herdr";
          sound.enabled = true;
        };
        keys.prefix = "ctrl+b";
        keys.command = [
          {
            key = "prefix+l";
            type = "plugin_action";
            command = "example.layout.apply";
            description = "apply layout";
          }
        ];
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [cfg.package];

    # Herdr stores mutable local data beside Home Manager's generated config.toml.
    persist.storage.directories = [".config/herdr"];

    # Home Manager owns config.toml, so Herdr cannot record onboarding itself.
    programs.herdr.settings.onboarding = false;

    programs.herdr.settings.ui.toast.delivery = "herdr";

    # Match the direct shortcuts in tmux.conf.
    programs.herdr.settings.keys = {
      prefix = "alt+z";

      new_workspace = "alt+n";
      workspace_picker = "alt+a";
      detach = "alt+d";

      new_tab = "alt+t";
      previous_tab = "alt+[";
      next_tab = "alt+]";
      move_tab_previous = "ctrl+alt+[";
      move_tab_next = "ctrl+alt+]";
      indexed.tabs = "alt";

      split_horizontal = "alt+u";
      split_vertical = "alt+i";
      close_pane = "alt+w";
      last_pane = "alt+o";

      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";

      command =
        map (binding: {
          key = "alt+${binding.key}";
          type = "shell";
          command = "${lib.getExe navigate} ${binding.direction} ${binding.key}";
          description = "Navigate ${binding.direction} in Emacs or Herdr";
        }) [
          {
            key = "h";
            direction = "left";
          }
          {
            key = "j";
            direction = "down";
          }
          {
            key = "k";
            direction = "up";
          }
          {
            key = "l";
            direction = "right";
          }
        ];

      resize_pane_left = "alt+shift+h";
      resize_pane_down = "alt+shift+j";
      resize_pane_up = "alt+shift+k";
      resize_pane_right = "alt+shift+l";
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "herdr-config.toml" cfg.settings;
      onChange = let
        binPath =
          if cfg.package == null
          then "herdr"
          else lib.getExe cfg.package;
      in "${binPath} server reload-config || true";
    };
  };
}
