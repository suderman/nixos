{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.claude-quota;
  inherit (lib) mkIf mkMerge mkOption types;
  icon = "✻";
  usagePage = "https://claude.ai/settings/usage";
  open = "${pkgs.xdg-utils}/bin/xdg-open ${usagePage}";

  # Read Claude Code's subscription usage and summarize it for the bar (default) or popup.
  # Never refresh the OAuth token here: rotating it could sign Claude Code out.
  # The bar and popup share one cache so the API sees at most one request per
  # cacheSeconds, and a 429 backs off until Retry-After while showing the last data.
  status = pkgs.self.mkScript {
    name = "claude-quota-status";
    path = [pkgs.curl pkgs.jq pkgs.util-linux];
    env = {
      CLAUDE_CREDENTIALS = cfg.credentials;
      CLAUDE_QUOTA_ICON = icon;
      CLAUDE_QUOTA_TTL = toString cfg.cacheSeconds;
    };
    text =
      # bash
      ''
        mode="''${1:-bar}"
        cache="''${XDG_RUNTIME_DIR:?}/claude-quota"
        mkdir -p -m 700 "$cache"
        tmp="$(mktemp -d "$cache/tmp.XXXXXX")"
        trap 'rm -rf "$tmp"' EXIT
        now="$(date +%s)"

        plan=""
        expires=""
        if [[ -r $CLAUDE_CREDENTIALS ]]; then
          plan="$(jq -r '.claudeAiOauth.subscriptionType // ""' "$CLAUDE_CREDENTIALS")"
          expires="$(jq -r '.claudeAiOauth.expiresAt // 0' "$CLAUDE_CREDENTIALS")"
        fi

        summarize() {
          jq -cn --arg mode "$mode" --arg icon "$CLAUDE_QUOTA_ICON" --arg plan "$plan" \
            --arg expires "$expires" "$@" -f ${./claude-quota.jq}
        }

        # Show cached data, noting why it is stale when a refresh failed.
        cached() {
          summarize --arg failure "" --arg message "" --arg stale "''${1-}" \
            --arg fetched "$(<"$cache/fetched")" --slurpfile usage "$cache/usage.json"
          exit 0
        }

        fail() {
          [[ -s $cache/usage.json ]] && cached "$1"
          summarize --arg failure "$1" --arg message "$2" --arg stale "" --arg fetched "" --argjson usage '[]'
          exit 0
        }

        # Serialize the bar and popup so only one of them fetches.
        exec 9>"$cache/lock"
        flock 9

        if [[ -s $cache/usage.json && -s $cache/fetched ]] && ((now - $(<"$cache/fetched") < CLAUDE_QUOTA_TTL)); then
          cached
        fi
        if [[ -s $cache/retry-at ]] && ((now < $(<"$cache/retry-at"))); then
          fail ratelimited "Anthropic is rate limiting usage requests; retrying after $(date -d "@$(<"$cache/retry-at")" +%-I:%M%P)."
        fi

        [[ -r $CLAUDE_CREDENTIALS ]] || fail missing "Sign in with claude to create $CLAUDE_CREDENTIALS."
        if ((expires / 1000 <= now)); then
          fail expired "Claude Code refreshes its token when it runs. Start claude, then refresh."
        fi

        # Pass the token through a private curl config, never as an argument.
        jq -r '"header = \"Authorization: Bearer \(.claudeAiOauth.accessToken)\""' \
          "$CLAUDE_CREDENTIALS" >"$tmp/auth"
        code="$(curl --silent --show-error --max-time 10 --connect-timeout 3 --config "$tmp/auth" \
          --header 'anthropic-beta: oauth-2025-04-20' --write-out '%{http_code}' \
          --dump-header "$tmp/headers" --output "$tmp/usage.json" \
          https://api.anthropic.com/api/oauth/usage 2>"$tmp/error")" ||
          fail offline "Failed to reach api.anthropic.com"$'\n'"$(<"$tmp/error")"
        case "$code" in
        2??) ;;
        429)
          retry="$(sed -n 's/^[Rr]etry-[Aa]fter: *\([0-9]*\).*/\1/p' "$tmp/headers")"
          echo $((now + ''${retry:-300})) >"$cache/retry-at"
          fail ratelimited "Anthropic is rate limiting usage requests (HTTP 429); retrying after $(date -d "@$(<"$cache/retry-at")" +%-I:%M%P)."
          ;;
        401 | 403) fail auth "Claude rejected the stored token (HTTP $code). Start claude to sign in again." ;;
        *) fail http "Claude usage returned HTTP $code." ;;
        esac

        jq -e '.five_hour and .seven_day' "$tmp/usage.json" >/dev/null 2>&1 ||
          fail parse "Claude usage returned an unexpected response."
        mv "$tmp/usage.json" "$cache/usage.json"
        echo "$now" >"$cache/fetched"
        rm -f "$cache/retry-at"
        cached
      '';
  };

  popup = pkgs.replaceVars ./claude-quota.qml {
    ICON = icon;
    DATA_COMMAND = lib.getExe status;
    OPEN_COMMAND = "${pkgs.xdg-utils}/bin/xdg-open";
    USAGE_URL = usagePage;
    INTERVAL_MS = toString (cfg.interval * 1000);
  };
in {
  options.wayland.windowManager.hyprland.waybar.claude-quota = {
    enable = lib.mkEnableOption "Claude subscription quota Waybar widget";

    credentials = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.claude/.credentials.json";
      description = "Claude Code OAuth credentials to read the usage token from.";
    };

    interval = mkOption {
      type = types.ints.positive;
      default = 120;
      description = "Polling interval in seconds.";
    };

    cacheSeconds = mkOption {
      type = types.ints.positive;
      default = 60;
      description = "Minimum seconds between usage API requests, shared by the bar and popup.";
    };

    popup.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the Quickshell detailed quota popup on click.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.waybar.settings.bar."custom/claude-quota" = {
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
          then "${lib.getExe config.lib.quickshell.ipc} claude-quota toggle"
          else open;
      };
    }

    (mkIf cfg.popup.enable {
      wayland.windowManager.hyprland.quickshell = {
        enable = true;
        components = ["ClaudeQuota {}"];
        files."ClaudeQuota.qml" = popup;
      };
    })
  ]);
}
