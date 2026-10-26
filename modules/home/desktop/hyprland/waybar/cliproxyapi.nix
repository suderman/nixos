{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.cliproxyapi;
  managementUrl = "${lib.removeSuffix "/" cfg.url}/management.html";
  open = "${pkgs.xdg-utils}/bin/xdg-open ${lib.escapeShellArg managementUrl}";
  status = pkgs.self.mkScript {
    name = "cliproxyapi-quota-status";
    path = [pkgs.curl pkgs.jq pkgs.util-linux];
    env.CLIPROXYAPI_QUOTA_URL = cfg.quotaUrl;
    text =
      # bash
      ''
        mode="''${1:-bar}"
        cache="''${XDG_RUNTIME_DIR:?}/cliproxyapi-quota"
        mkdir -p -m 700 "$cache"
        exec 9>"$cache/lock"
        flock 9
        tmp="$(mktemp -d "$cache/tmp.XXXXXX")"
        trap 'rm -rf "$tmp"' EXIT
        failure=""
        if curl --silent --fail --max-time 10 --connect-timeout 3 \
          "$CLIPROXYAPI_QUOTA_URL" >"$tmp/quota.json" &&
          jq -e 'type == "object" and (.accounts | type == "array") and has("fetched")' "$tmp/quota.json" >/dev/null 2>&1; then
          mv "$tmp/quota.json" "$cache/quota.json"
        else
          failure="Quota snapshot unreachable. Open management to check CLIProxyAPI."
        fi
        if [[ ! -s $cache/quota.json ]]; then
          printf '%s' '{"accounts": [], "fetched": null}' >"$tmp/quota.json"
        else
          cp "$cache/quota.json" "$tmp/quota.json"
        fi
        jq --arg mode "$mode" --arg failure "$failure" -c -f ${./cliproxyapi.jq} "$tmp/quota.json"
      '';
  };
in {
  options.wayland.windowManager.hyprland.waybar.cliproxyapi = {
    enable = lib.mkEnableOption "read-only CLIProxyAPI Waybar quota widget";
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://cliproxyapi.kit";
      description = "CLIProxyAPI base URL, used to open its management page.";
    };
    quotaUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cliproxyapi-quota.kit/quota.json";
      description = "Private read-only subscription quota snapshot URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.waybar.settings.bar."custom/cliproxyapi" = {
      return-type = "json";
      exec = lib.getExe status;
      format = "{text}";
      escape = true;
      interval = 60;
      tooltip = true;
      on-click = "${lib.getExe config.lib.quickshell.ipc} cliproxyapi toggle";
      on-click-right = open;
    };

    wayland.windowManager.hyprland.quickshell = {
      enable = true;
      components = ["CliProxyApi {}"];
      files."CliProxyApi.qml" = pkgs.replaceVars ./cliproxyapi.qml {
        DATA_COMMAND = lib.getExe status;
        OPEN_COMMAND = "${pkgs.xdg-utils}/bin/xdg-open";
        MANAGEMENT_URL = managementUrl;
      };
    };
  };
}
