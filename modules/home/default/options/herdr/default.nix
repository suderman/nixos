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

  # wrapped herdr to own workspace emacs servers
  herdr = pkgs.self.mkScript {
    name = "herdr";
    path = with pkgs; [coreutils gawk gnugrep procps systemd];
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

        # A bare client that finds no server starts one with this shell's
        # environment. Over SSH that means SSH_CONNECTION and no WAYLAND_DISPLAY,
        # so image paste fails in every pane. Start the user unit instead, which
        # carries the desktop session's environment, and wait for it.
        running() { ${lib.getExe cfg.package} status server 2>/dev/null | grep -qx 'status: running'; }
        if [[ $# -eq 0 ]] && ! running && systemctl --user start herdr.service 2>/dev/null; then
          for _ in $(seq 50); do
            running && break
            sleep 0.1
          done
        fi

        exec ${lib.getExe cfg.package} "$@"
      '';
  };
in {
  # Keybindings and plugins each have their own file beside this one.
  imports = flake.lib.ls ./.;

  # Avoid duplicate options when release-26.11 imports the upstream module.
  disabledModules = ["programs/herdr.nix"];

  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = mkOption {
      type = lib.types.nullOr lib.types.package;
      default = perSystem.herdr.default;
      description = "The Herdr package to use.";
    };

    workers = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["kit" "cog" "lux"];
      description = ''
        Hosts whose Herdr servers run agents. The desktop agent roster polls
        each one over SSH, and always includes this host. Headless workers
        start their server at boot.
      '';
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
    home.packages = [herdr];

    # Herdr stores mutable local data beside Home Manager's generated config.toml.
    persist.storage.directories = [".config/herdr"];

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "herdr-config.toml" cfg.settings;
      onChange = "${cfg.package} server reload-config || true";
    };

    # Run the server at login so it survives reboots and closed clients. Clients
    # and the Org dispatcher attach to it. Headless workers start it at boot
    # through user lingering; other headless hosts start it on first attach.
    systemd.user.services.herdr = let
      # Skip when a client already started a server outside this unit.
      notRunning = pkgs.self.mkScript {
        name = "herdr-not-running";
        path = [cfg.package pkgs.gnugrep];
        text = ''
          status=$(herdr status server)
          ! grep -qx 'status: running' <<<"$status"
        '';
      };
    in {
      Unit = {
        Description = "Herdr server";
        After = lib.optional config.desktop.enable "graphical-session.target";
        # Restarting kills every pane and agent; new versions wait for login.
        X-RestartIfChanged = false;
      };
      Service = {
        ExecCondition = lib.getExe notRunning;
        ExecStart = "${lib.getExe herdr} server";
        ExecStop = "${lib.getExe herdr} server stop";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy =
        if config.desktop.enable
        then ["graphical-session.target"]
        else lib.optional (lib.elem config.networking.hostName cfg.workers) "default.target";
    };
  };
}
