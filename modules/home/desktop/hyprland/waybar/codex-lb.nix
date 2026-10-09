{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.codex-lb;
  inherit (lib) mkIf mkMerge mkOption types;
  open = "${pkgs.xdg-utils}/bin/xdg-open ${lib.escapeShellArg cfg.url}";

  # Fetch the dashboard once and summarize it for the bar (default) or popup.
  status = pkgs.self.mkScript {
    name = "codex-lb-status";
    path = [pkgs.curl pkgs.jq];
    env = {
      CODEX_LB_URL = cfg.url;
      CODEX_LB_ICON = "󰊚";
      CODEX_LB_ALERT_COLOR = "#${config.lib.stylix.colors.base08}";
    };
    text =
      # bash
      ''
        mode="''${1:-bar}"
        limit=1
        [[ $mode == popup ]] && limit=100
        url="''${CODEX_LB_URL%/}"
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT

        summarize() {
          jq -cn --arg mode "$mode" --arg url "$url" --arg icon "$CODEX_LB_ICON" \
            --arg alert_color "$CODEX_LB_ALERT_COLOR" "$@" -f ${./codex-lb.jq}
        }

        fail() {
          summarize --arg failure "$1" --arg message "$2" \
            --argjson overview '[]' --argjson projections '[]' --argjson logs '[]'
          exit 0
        }

        fetch() {
          local code
          code="$(curl --silent --show-error --location --max-time 10 --connect-timeout 3 \
            --write-out '%{http_code}' --output "$tmp/$1.json" "$url$2" 2>"$tmp/error")" ||
            fail offline "Failed to reach $url$2"$'\n'"$(<"$tmp/error")"
          case "$code" in
          2??) ;;
          401 | 403) fail auth "Dashboard read access is required. Enable read-only guest access in codex-lb."$'\n\n'"URL: $url" ;;
          *) fail http "codex-lb returned HTTP $code for $2."$'\n\n'"URL: $url" ;;
          esac
        }

        fetch overview "/api/dashboard/overview?timeframe=7d"
        fetch projections /api/dashboard/projections
        fetch logs "/api/request-logs?limit=$limit"

        summarize --arg failure "" --arg message "" \
          --slurpfile overview "$tmp/overview.json" \
          --slurpfile projections "$tmp/projections.json" \
          --slurpfile logs "$tmp/logs.json" 2>"$tmp/error" ||
          fail parse "Failed to parse codex-lb dashboard response."$'\n'"$(<"$tmp/error")"
      '';
  };

  # Pause or resume an account, logging in to the dashboard when asked to.
  accountAction = pkgs.self.mkScript {
    name = "codex-lb-account-action";
    path = [pkgs.curl pkgs.jq];
    env.CODEX_LB_URL = cfg.url;
    text =
      # bash
      ''
        account_id="''${1:-}"
        action="''${2:-}"
        auth_mode="''${3:-}"
        url="''${CODEX_LB_URL%/}"
        cookies="''${XDG_RUNTIME_DIR:?}/codex-lb-dashboard.cookies"
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT

        result() {
          jq -cn --argjson ok "$1" --arg message "$2" \
            --argjson authRequired "''${3:-false}" --argjson usernameRequired "''${4:-false}" \
            '{ok: $ok, message: $message, authRequired: $authRequired, usernameRequired: $usernameRequired}'
          exit 0
        }

        error_message() {
          jq -r --arg fallback "$2" '.error.message // $fallback' "$1" 2>/dev/null || printf '%s' "$2"
        }

        # POST with the dashboard session cookie and print the HTTP status.
        post() {
          local path="$1" output="$2"
          shift 2
          curl --silent --show-error --location --max-time 15 --connect-timeout 3 \
            --request POST --cookie "$cookies" --cookie-jar "$cookies" \
            --write-out '%{http_code}' --output "$output" "$@" "$url$path" 2>"$tmp/error" || true
        }

        [[ $account_id =~ ^[A-Za-z0-9._-]+$ ]] || result false "Invalid account id."
        case "$action" in
        pause) endpoint=pause ;;
        resume) endpoint=reactivate ;;
        *) result false "Unknown account action." ;;
        esac

        umask 077
        touch "$cookies"
        chmod 600 "$cookies"

        code="$(post "/api/accounts/$account_id/$endpoint" "$tmp/action.json")"
        if [[ $code == 401 || $code == 403 ]]; then
          [[ $auth_mode == login ]] || result false "Dashboard login required." true

          # The popup writes {"username", "password"} on stdin; never pass it as an argument.
          IFS= read -r credentials || true
          printf '%s' "$credentials" |
            jq -e 'type == "object" and (.password | type == "string" and length > 0) and ((.username // "") | type == "string")' \
              >/dev/null 2>&1 || result false "Dashboard password is required." true
          printf '%s' "$credentials" |
            jq -c 'if (.username // "") == "" then {password} else {username, password} end' >"$tmp/login-request.json"
          unset credentials

          login="$(post /api/dashboard-auth/password/login "$tmp/login.json" \
            --header 'Content-Type: application/json' --data-binary @"$tmp/login-request.json")"
          if [[ $login == 422 && $(jq -r '.error.code // ""' "$tmp/login.json" 2>/dev/null) == username_required ]]; then
            result false "Dashboard username is also required." true true
          fi
          [[ $login == 2?? ]] || result false "$(error_message "$tmp/login.json" "Dashboard login failed.")" true

          code="$(post "/api/accounts/$account_id/$endpoint" "$tmp/action.json")"
        fi

        if [[ $code == 2?? ]]; then
          state="$(jq -r '.status // empty' "$tmp/action.json" 2>/dev/null || true)"
          result true "Account ''${state:-updated}."
        elif [[ -s $tmp/action.json ]]; then
          result false "$(error_message "$tmp/action.json" "Account change failed.")"
        else
          result false "Failed to reach $url: $(<"$tmp/error")"
        fi
      '';
  };

  popup = pkgs.replaceVars ./codex-lb.qml {
    DATA_COMMAND = lib.getExe status;
    ACCOUNT_COMMAND = lib.getExe accountAction;
    OPEN_COMMAND = "${pkgs.xdg-utils}/bin/xdg-open";
    INTERVAL_MS = toString (cfg.interval * 1000);
  };
in {
  options.wayland.windowManager.hyprland.waybar.codex-lb = {
    enable = lib.mkEnableOption "codex-lb Waybar quota widget";

    url = mkOption {
      type = types.str;
      default = "https://codex-lb.kit";
      example = "https://codex-lb.cog";
      description = "Base URL for the codex-lb dashboard.";
    };

    interval = mkOption {
      type = types.ints.positive;
      default = 60;
      description = "Polling interval in seconds.";
    };

    popup.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Quickshell detailed quota popup on click.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.waybar.settings.bar."custom/codex-lb" = {
        return-type = "json";
        exec = lib.getExe status;
        format = "{text}";
        escape = false;
        max-length = 32;
        inherit (cfg) interval;
        tooltip = true;
        on-click-right = open;
        on-click =
          if cfg.popup.enable
          then "${lib.getExe config.lib.quickshell.ipc} codex-lb toggle"
          else open;
      };
    }

    (mkIf cfg.popup.enable {
      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = ["CodexLb {}"];
        files."CodexLb.qml" = popup;
      };
    })
  ]);
}
