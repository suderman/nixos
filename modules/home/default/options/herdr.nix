{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml {};

  edger = pkgs.self.mkScript {
    name = "edger";
    path = [cfg.package pkgs.jq pkgs.procps];
    text = builtins.readFile "${flake.inputs.edger}/bin/edger";
  };

  herdr = pkgs.self.mkScript {
    name = "herdr";
    path = with pkgs; [coreutils gawk gnugrep procps];
    text =
      # bash
      ''
        if [[ $# -eq 2 && $1 == server && $2 == stop ]]; then
          socket=$(${lib.getExe cfg.package} status server | awk '$1 == "socket:" {print $2}')
          [[ -n $socket ]] || { echo 'herdr: cannot find server socket; refusing to stop' >&2; exit 1; }

          # The pane exits during stop, so terminate its detached Emacs daemons first.
          for pid in $(pgrep -u "$(id -u)" -f -- '--daemon=em-' || true); do
            grep -zFxq "HERDR_SOCKET_PATH=$socket" "/proc/$pid/environ" 2>/dev/null || continue
            grep -zEq '^(TMUX|TMUX_PANE)=' "/proc/$pid/environ" 2>/dev/null && continue
            grep -zEq '^--daemon=em-[[:xdigit:]]{24}$' "/proc/$pid/cmdline" 2>/dev/null || continue
            kill "$pid" 2>/dev/null || true
          done
        fi

        exec ${lib.getExe cfg.package} "$@"
      '';
  };

  ntfyPlugin = pkgs.buildGoModule {
    pname = "herdr-ntfysh";
    version = "0.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "cobanov";
      repo = "herdr-ntfysh";
      rev = "f07462439b7dde0ac08ffe90d30661520037d561";
      hash = "sha256-0RjvBD/J53/iT5e9KQAoQomnnkxpQ+9EGgcS5Etvr7A=";
    };
    vendorHash = null;
    postInstall = ''
      install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
      ln -s bin/herdr-ntfysh "$out/herdr-ntfysh"
    '';
  };
in {
  # Avoid duplicate options when release-26.11 imports the upstream module.
  disabledModules = ["programs/herdr.nix"];

  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = mkOption {
      type = lib.types.nullOr lib.types.package;
      default = perSystem.herdr.default;
      description = "The Herdr package to use.";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = {};
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [herdr edger];

    # Herdr stores mutable local data beside Home Manager's generated config.toml.
    persist.storage.directories = [".config/herdr"];

    xdg.configFile."herdr/plugins/config/cobanov.herdr-ntfysh/.env" = {
      text = ''
        HERDR_NTFY_SERVER=https://ntfy.hub
        HERDR_NTFY_TOPIC=herdr
      '';
      force = true;
    };

    home.activation.herdrNtfyPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      $DRY_RUN_CMD ${lib.getExe cfg.package} plugin link ${ntfyPlugin}
    '';

    # Home Manager owns config.toml, so Herdr cannot record onboarding itself.
    programs.herdr.settings = {
      onboarding = false;
      ui.toast.delivery = "herdr";
      ui.sidebar.spaces.rows = [["state_icon" "workspace" "branch"]];

      keys = {
        prefix = "alt+z";

        new_workspace = "alt+shift+n";
        rename_workspace = "prefix+period";
        workspace_picker = "alt+a";
        detach = "prefix+d";

        new_tab = "alt+shift+t";
        rename_tab = "prefix+comma";
        previous_tab = "prefix+[";
        next_tab = "prefix+]";
        move_tab_previous = "prefix+{";
        move_tab_next = "prefix+}";
        copy_mode = "prefix+m";

        split_horizontal = "prefix+u";
        split_vertical = "prefix+i";
        close_pane = "alt+shift+w";
        last_pane = "prefix+o";

        focus_pane_left = "prefix+h";
        focus_pane_down = "prefix+j";
        focus_pane_up = "prefix+k";
        focus_pane_right = "prefix+l";

        command = let
          modifier = "alt";
          binds.direction = {
            left = "h";
            down = "j";
            up = "k";
            right = "l";
          };
          binds.action = {
            horizontal = "u";
            vertical = "i";
            close = "w";
          };
        in
          lib.mapAttrsToList (direction: letter: {
            key = "${modifier}+${letter}";
            type = "shell";
            command = "${lib.getExe edger} ${direction} ${modifier}+${letter}";
            description = "Navigate ${direction} across editor, pane, and outer layer";
          })
          binds.direction
          ++ lib.mapAttrsToList (direction: letter: {
            key = "${modifier}+shift+${letter}";
            type = "shell";
            command = "${lib.getExe edger} resize ${direction} ${modifier}+shift+${letter}";
            description = "Navigate ${direction} across editor, pane, and outer layer";
          })
          binds.direction
          ++ lib.mapAttrsToList (action: letter: {
            key = "${modifier}+${letter}";
            type = "shell";
            command = "${lib.getExe edger} ${action} ${modifier}+${letter}";
            description = "Edger ${action}";
          })
          binds.action;
      };
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "herdr-config.toml" cfg.settings;
      onChange = "${cfg.package} server reload-config || true";
    };
  };
}
