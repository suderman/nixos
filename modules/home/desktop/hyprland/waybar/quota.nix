{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.waybar.quota;
  status = pkgs.self.mkScript {
    name = "june-quota-status";
    path = [pkgs.jq config.programs.june.package];
    text =
      # bash
      ''
        # June reads each subscription account's quota through a login on this host (june quota); its own
        # two-minute cache keeps the bar from polling the providers. The popup's Refresh asks for a fresh read.
        mode="''${1:-bar}"
        failure=""
        refresh=()
        [[ $mode == refresh ]] && { mode=popup; refresh=(--refresh); }
        if ! quota="$(june quota --json "''${refresh[@]}" 2>/dev/null)" || ! jq -e 'type == "array"' <<<"$quota" >/dev/null 2>&1; then
          failure="June could not read quota. Run june quota to see why."
          quota="[]"
        fi
        # The bar and popup read the snapshot shape they were written for.
        jq -c '
          {"openai": "codex", "anthropic": "claude", "google": "antigravity"} as $ids |
          {fetched: (now | floor), error: "", accounts: [.[] | {
            provider: $ids[.provider],
            label: ([(.number | tostring), .label, .email] | map(select(. != null)) | join(" · ")),
            windows: .windows, plan: (.plan // ""), fetched: (.fetched // null), error: (.error // ""),
            disabled: false, unavailable: false
          }]}' <<<"$quota" |
          jq --arg mode "$mode" --arg failure "$failure" -c -f ${./quota.jq}
      '';
  };
in {
  options.wayland.windowManager.hyprland.waybar.quota.enable =
    lib.mkEnableOption "the read-only subscription quota widget, from June's june quota";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.june.enable;
        message = "waybar.quota reads june quota: enable programs.june";
      }
    ];

    programs.waybar.settings.bar."custom/quota" = {
      return-type = "json";
      exec = lib.getExe status;
      format = "{text}";
      escape = true;
      interval = 60;
      tooltip = true;
      on-click = "${lib.getExe config.lib.quickshell.ipc} quota toggle";
    };

    wayland.windowManager.hyprland.quickshell = {
      enable = true;
      components = ["Quota {}"];
      files."Quota.qml" = pkgs.replaceVars ./quota.qml {
        DATA_COMMAND = lib.getExe status;
      };
    };
  };
}
