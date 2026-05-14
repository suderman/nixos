{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.camofox-browser;

  derivePort =
    name: base:
    let
      op = acc: char: lib.mod ((acc * 33) + lib.strings.charToInt char) base;
      chars = lib.strings.stringToCharacters "${toString base}:${name}";
    in
    base + 1 + (builtins.foldl' op 5381 chars);

  deriveServicePort =
    service: profile: base:
    derivePort "${service}:${profile}" base;

  hermesProfiles =
    if config.services.hermes-agent.enable then config.lib.hermes-agent.gatewayAgents else [ ];
  hermesDataDir =
    if config.services.hermes-agent.enable then
      config.lib.hermes-agent.dataDir
    else
      "${config.home.homeDirectory}/.local/share/hermes";

  profiles = lib.unique (cfg.profiles ++ hermesProfiles);
  camofoxEnabled = cfg.enable && profiles != [ ];
  runFileFor = profile: kind: "${cfg.runDir}/camofox-${profile}-${kind}";
  shareDirFor = profile: "${config.home.homeDirectory}/${cfg.dataDir}/${profile}";
  cookiesDirFor = profile: "${shareDirFor profile}/cookies";
  profilesDirFor = profile: "${shareDirFor profile}/profiles";
  stateDirFor = profile: "${config.home.homeDirectory}/${cfg.stateDir}/${profile}";
  tracesDirFor = profile: "${stateDirFor profile}/traces";
  cacheDirFor = profile: "${config.home.homeDirectory}/${cfg.cacheDir}/${profile}";
  apiPortFor =
    profile: deriveServicePort "camofox" profile (cfg.apiBasePort + config.home.portOffset);
  vncPortFor =
    profile: deriveServicePort "camofox-vnc" profile (cfg.vncBasePort + config.home.portOffset);
  helperPortFor =
    profile:
    deriveServicePort "camofox-vnc-helper" profile (cfg.helperBasePort + config.home.portOffset);
  displayFor = profile: deriveServicePort "camofox-display" profile 100;
  rfbPortFor = profile: 5900 + displayFor profile;
  tmpEnvFor =
    profile:
    let
      cacheDir = cacheDirFor profile;
    in
    [
      "XDG_CACHE_HOME=${cacheDir}"
      "TMPDIR=${cacheDir}"
      "TMP=${cacheDir}"
      "TEMP=${cacheDir}"
    ];
  browserServicePath = [
    pkgs.coreutils
    pkgs.xorg.xorgserver
    pkgs.xorg.xauth
    pkgs.xorg.xhost
    pkgs.xorg.xrandr
    pkgs.novnc
    websockifyWrapped
  ];
  sandboxDefaults = {
    NoNewPrivileges = true;
    PrivateTmp = false;
    ProtectSystem = "strict";
    ProtectHome = false;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = false;
  };
  runtimeLibs = [
    pkgs.alsa-lib
    pkgs.atk
    pkgs.cairo
    pkgs.dbus-glib
    pkgs.gdk-pixbuf
    pkgs.glib
    pkgs.gtk3
    pkgs.libdrm
    pkgs.mesa
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.xorg.libX11
    pkgs.xorg.libXScrnSaver
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXcursor
    pkgs.xorg.libXdamage
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXi
    pkgs.xorg.libXrandr
    pkgs.xorg.libXrender
    pkgs.xorg.libXtst
    pkgs.xorg.libxcb
    pkgs.xorg.libxkbfile
  ];
  runtimeLibPath = lib.makeLibraryPath runtimeLibs;
  websockifyWrapped = pkgs.self.mkScript {
    name = "websockify";
    text =
      # bash
      ''
        args=("$@")
        for ((i=0; i<''${#args[@]}-1; i++)); do
          if [[ "''${args[$i]}" == "--web" && "''${args[$((i+1))]}" == "/opt/noVNC" ]]; then
            args[$((i+1))]="${pkgs.novnc}/share/webapps/novnc"
          fi
        done

        exec "${pkgs.python3Packages.websockify}/bin/websockify" "''${args[@]}"
      '';
  };

  camofox-init = pkgs.self.mkScript {
    name = "camofox-browser";
    path = [ pkgs.nodejs ];
    text =
      # bash
      ''
        export NPM_CONFIG_PREFIX="${config.home.sessionVariables.NPM_CONFIG_PREFIX}"
        export NPM_CONFIG_CACHE="${config.home.sessionVariables.NPM_CONFIG_CACHE}"

        CAMOFOX_BIN="''${CAMOFOX_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/camofox-browser}"
        CAMOFOX_INIT_STAMP="''${CAMOFOX_INIT_STAMP:-${config.home.homeDirectory}/.local/state/camofox-browser/init.timestamp}"
        CAMOFOX_INIT_INTERVAL="$((24 * 60 * 60))"

        camofox_init() {
          npm i -g camofox-browser

          if [[ ! -f "$CAMOFOX_BIN" ]]; then
            echo "Failed to install camofox-browser binary" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$CAMOFOX_INIT_STAMP")"
          date +%s >"$CAMOFOX_INIT_STAMP"
        }

        camofox_init_stale() {
          [[ ! -f "$CAMOFOX_INIT_STAMP" ]] && return 0

          local now last
          now="$(date +%s)"
          last="$(<"$CAMOFOX_INIT_STAMP")"

          [[ ! "$last" =~ ^[0-9]+$ ]] && return 0
          ((now - last >= CAMOFOX_INIT_INTERVAL))
        }

        if [[ "''${1:-}" == "init" ]]; then
          camofox_init
          exit 0
        fi

        if [[ "''${1:-}" == "ensure" ]]; then
          if [[ ! -e "$CAMOFOX_BIN" ]] || camofox_init_stale; then
            camofox_init
          fi
          exit 0
        fi

        if [[ ! -e "$CAMOFOX_BIN" ]] || camofox_init_stale; then
          camofox_init
        fi

        exec "$CAMOFOX_BIN" "$@"
      '';
  };
in
{
  options.services.camofox-browser = {
    enable = lib.mkEnableOption "camofox-browser";

    name = lib.mkOption {
      type = lib.types.str;
      default = "camofox";
      description = "Base Traefik/DNS name for Camofox routes.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Wrapper package that installs and runs camofox-browser.";
    };

    profiles = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Profile names to run as separate Camofox service instances.";
    };

    apiBasePort = lib.mkOption {
      type = lib.types.port;
      default = 9377;
      description = "Base port namespace used to derive per-profile Camofox API ports.";
    };

    vncBasePort = lib.mkOption {
      type = lib.types.port;
      default = 6080;
      description = "Base port namespace used to derive per-profile Camofox noVNC ports.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/camofox-browser";
      description = "Base data directory for Camofox profile state.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/state/camofox-browser";
      description = "Base state directory for Camofox runtime state.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.str;
      default = ".cache/camofox-browser";
      description = "Base cache directory for Camofox instances.";
    };

    runDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/camofox/${toString config.home.uid}";
      description = "Runtime directory for derived Camofox secrets.";
    };

    enableVnc = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable virtual display support for Camofox.";
    };

    vncTimeoutMs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1800000;
      description = "How long to keep the noVNC session alive after activation.";
    };

    helperBasePort = lib.mkOption {
      type = lib.types.port;
      default = 6180;
      description = "Base port namespace used to derive per-profile VNC wake helper ports.";
    };

    crashReports.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable upstream Camofox crash telemetry.";
    };
  };

  config = lib.mkIf camofoxEnabled {
    services.camofox-browser.package = lib.mkDefault camofox-init;
    toolchains.javascript.enable = true;
    persist.scratch.directories = [
      cfg.stateDir
      cfg.cacheDir
    ];

    tmpfiles.directories = lib.concatMap (profile: [
      {
        target = "${cfg.dataDir}/${profile}";
        mode = 700;
      }
      {
        target = "${cfg.dataDir}/${profile}/cookies";
        mode = 700;
      }
      {
        target = "${cfg.dataDir}/${profile}/profiles";
        mode = 700;
      }
      {
        target = "${cfg.stateDir}/${profile}";
        mode = 700;
      }
      {
        target = "${cfg.stateDir}/${profile}/traces";
        mode = 700;
      }
      {
        target = "${cfg.cacheDir}/${profile}";
        mode = 700;
      }
    ]) profiles;

    tmpfiles.files = map (profile: {
      target = lib.removePrefix "${config.home.homeDirectory}/" "${hermesDataDir}/${profile}/.env.camofox";
      mode = 600;
      text = ''
        CAMOFOX_URL=http://127.0.0.1:${toString (apiPortFor profile)}
        CAMOFOX_API_KEY_FILE=${runFileFor profile "api-key"}
        CAMOFOX_ACCESS_KEY_FILE=${runFileFor profile "access-key"}
        CAMOFOX_ADMIN_KEY_FILE=${runFileFor profile "admin-key"}
      '';
    }) hermesProfiles;

    home.file.".local/bin/camofox-browser".source = "${cfg.package}/bin/camofox-browser";

    systemd.user.services = {
      camofox-browser-init = {
        Unit = {
          Description = "Install or refresh camofox-browser";
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${cfg.package}/bin/camofox-browser ensure";
        };

        Install.WantedBy = [ "default.target" ];
      };
    }
    // lib.listToAttrs (
      map (
        profile:
        let
          path = config.home.sessionPath ++ [
            "${config.home.profileDirectory}/bin"
            "/run/current-system/sw/bin"
            "/usr/bin"
            "/bin"
          ];
          script = pkgs.self.mkScript {
            name = "camofox-${profile}";
            path = browserServicePath;
            text =
              # bash
              ''
                export CAMOFOX_HOST=127.0.0.1
                export CAMOFOX_PORT=${toString (apiPortFor profile)}
                export LD_LIBRARY_PATH='${runtimeLibPath}'
                unset WAYLAND_DISPLAY
                unset WAYLAND_SOCKET
                export XDG_SESSION_TYPE=x11
                export CAMOFOX_HEADLESS=${if cfg.enableVnc then "false" else "true"}
                export CAMOFOX_COOKIES_DIR='${cookiesDirFor profile}'
                export CAMOFOX_PROFILES_DIR='${profilesDirFor profile}'
                export CAMOFOX_TRACES_DIR='${tracesDirFor profile}'
                export CAMOFOX_CRASH_REPORT_ENABLED=${if cfg.crashReports.enable then "true" else "false"}
                export CAMOFOX_VNC_TIMEOUT_MS=${toString cfg.vncTimeoutMs}
                export NODE_ENV=production

                ${lib.optionalString cfg.enableVnc ''
                  export DISPLAY=:${toString (displayFor profile)}
                  export CAMOFOX_VNC_BASE_PORT=${toString (vncPortFor profile)}
                  export CAMOFOX_VNC_HOST=127.0.0.1
                  export CAMOFOX_VNC_RESOLUTION=1920x1080x24
                ''}

                if [[ -r '${runFileFor profile "admin-key"}' ]]; then
                  export CAMOFOX_ADMIN_KEY="$(cat '${runFileFor profile "admin-key"}')"
                fi

                exec '${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/camofox-browser'
              '';
          };
        in
        lib.nameValuePair "camofox-${profile}" {
          Unit = {
            Description = "Camofox browser server for profile ${profile}";
            After = [
              "network-online.target"
              "camofox-browser-init.service"
            ]
            ++ lib.optionals cfg.enableVnc [ "camofox-display-${profile}.service" ];
            Requires = [
              "camofox-browser-init.service"
            ]
            ++ lib.optionals cfg.enableVnc [ "camofox-display-${profile}.service" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "simple";
            Environment = [ "PATH=${lib.concatStringsSep ":" path}" ] ++ tmpEnvFor profile;
            ExecStart = "${script}/bin/camofox-${profile}";
            Restart = "always";
            RestartSec = 5;
            TimeoutStopSec = 30;
            TimeoutStartSec = 300;
            SuccessExitStatus = "0 143";
            KillMode = "control-group";
            ReadWritePaths = [ "/tmp" ];
          }
          // sandboxDefaults;

          Install.WantedBy = [ "default.target" ];
        }
      ) profiles
    )
    // lib.listToAttrs (
      map (
        profile:
        let
          display = toString (displayFor profile);
          rfbPort = toString (rfbPortFor profile);
          lockWriter = pkgs.self.mkScript {
            name = "camofox-display-post-${profile}";
            path = [ pkgs.coreutils ];
            text =
              # bash
              ''
                lock_file=/tmp/.X${display}-lock
                sleep 1
                printf '%10d\n' "$$" > "$lock_file"
              '';
          };
          lockCleaner = pkgs.self.mkScript {
            name = "camofox-display-poststop-${profile}";
            path = [ pkgs.coreutils ];
            text =
              # bash
              ''
                rm -f /tmp/.X${display}-lock
              '';
          };
        in
        lib.nameValuePair "camofox-display-${profile}" {
          Unit = {
            Description = "Dedicated Xvnc display for Camofox profile ${profile}";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.tigervnc}/bin/Xvnc :${display} -geometry 1920x1080 -depth 24 -localhost -SecurityTypes None -AlwaysShared -DisconnectClients=0 -rfbport ${rfbPort}";
            ExecStartPost = "-${lockWriter}/bin/camofox-display-post-${profile}";
            ExecStopPost = "${lockCleaner}/bin/camofox-display-poststop-${profile}";
            Restart = "always";
            RestartSec = 2;
            TimeoutStopSec = 15;
            ReadWritePaths = [ "/tmp" ];
          }
          // sandboxDefaults;

          Install.WantedBy = [ "default.target" ];
        }
      ) (lib.optionals cfg.enableVnc profiles)
    )
    // lib.listToAttrs (
      map (
        profile:
        let
          wsPort = toString (vncPortFor profile);
          rfbPort = toString (rfbPortFor profile);
        in
        lib.nameValuePair "camofox-websockify-${profile}" {
          Unit = {
            Description = "noVNC bridge for Camofox profile ${profile}";
            After = [
              "network-online.target"
              "camofox-display-${profile}.service"
            ];
            Requires = [ "camofox-display-${profile}.service" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${websockifyWrapped}/bin/websockify --web ${pkgs.novnc}/share/webapps/novnc ${wsPort} 127.0.0.1:${rfbPort}";
            Restart = "always";
            RestartSec = 2;
            TimeoutStopSec = 15;
          }
          // sandboxDefaults;

          Install.WantedBy = [ "default.target" ];
        }
      ) (lib.optionals cfg.enableVnc profiles)
    )
    // lib.listToAttrs (
      map (
        profile:
        let
          helper = pkgs.writeText "camofox-vnc-helper-${profile}.py" ''
            import json
            from urllib.error import HTTPError
            from http.server import BaseHTTPRequestHandler, HTTPServer
            from urllib.parse import urlsplit
            from urllib.request import Request, urlopen

            API = "http://127.0.0.1:${toString (apiPortFor profile)}"
            USER = ${builtins.toJSON profile}
            PORT = ${toString (helperPortFor profile)}

            def post_json(path, body):
                req = Request(API + path, data=json.dumps(body).encode(), headers={"content-type": "application/json"}, method="POST")
                with urlopen(req, timeout=30) as resp:
                    return json.loads(resp.read().decode())

            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    if self.path not in ["/", "/wake"]:
                        self.send_response(404)
                        self.end_headers()
                        return

                    try:
                        post_json("/start", {})
                        post_json("/tabs", {
                            "userId": USER,
                            "sessionKey": "vnc-viewer",
                        })
                        target = "http://127.0.0.1:${toString (vncPortFor profile)}/vnc.html?autoconnect=true&resize=scale"
                        parsed = urlsplit(target)
                        location = parsed.path or "/vnc.html"
                        if parsed.query:
                            location += "?" + parsed.query
                        self.send_response(302)
                        self.send_header("Location", location)
                        self.end_headers()
                    except HTTPError as err:
                        detail = err.read().decode(errors="replace").strip()
                        message = f"HTTP Error {err.code}: {err.reason}"
                        if detail:
                            message += f"\n{detail}"
                        body = ("failed to wake camofox vnc: %s\n" % message).encode()
                        self.send_response(502)
                        self.send_header("content-type", "text/plain; charset=utf-8")
                        self.send_header("content-length", str(len(body)))
                        self.end_headers()
                        self.wfile.write(body)
                    except Exception as err:
                        body = ("failed to wake camofox vnc: %s\n" % err).encode()
                        self.send_response(502)
                        self.send_header("content-type", "text/plain; charset=utf-8")
                        self.send_header("content-length", str(len(body)))
                        self.end_headers()
                        self.wfile.write(body)

                def log_message(self, fmt, *args):
                    return

            HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
          '';
        in
        lib.nameValuePair "camofox-vnc-helper-${profile}" {
          Unit = {
            Description = "Camofox VNC wake helper for profile ${profile}";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.python3}/bin/python ${helper}";
            Restart = "always";
            RestartSec = 5;
          };

          Install.WantedBy = [ "default.target" ];
        }
      ) (lib.optionals cfg.enableVnc profiles)
    );
  };
}
