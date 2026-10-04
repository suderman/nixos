{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr-hypr;
  helper = pkgs.writeShellScriptBin "herdr-hypr" ''
    export PATH=${lib.makeBinPath [config.programs.herdr.package osConfig.programs.hyprland.package]}:$PATH
    exec ${pkgs.python3}/bin/python3 ${./herdr-hypr.py} "$@"
  '';
in {
  options.programs.herdr-hypr = {
    enable = lib.mkEnableOption "ephemeral Herdr pairing for agent Chromium windows";
    package = lib.mkOption {
      type = lib.types.package;
      default = helper;
      description = "Herdr and Hyprland pairing helper.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.herdr.enable && config.programs.chromium.enable && config.wayland.windowManager.hyprland.lua.enable;
        message = "herdr-hypr requires Herdr, Chromium, and Hyprland Lua.";
      }
    ];
    home.packages = [cfg.package];
    programs.herdr.settings.keys.command = [
      {
        key = "prefix+alt+p";
        type = "shell";
        command = "${lib.getExe cfg.package} pair";
        description = "Pair this Herdr context with the active Hyprland workspace";
      }
    ];
    # Pi's bootstrap owns this writable file and restores it when the trial is disabled.
    home.activation.herdrHyprMcp = lib.mkIf (config.programs.pi-coding-agent.enable or false) (
      lib.hm.dag.entryAfter ["piAgentConfiguration"] ''
        mcp="${config.home.homeDirectory}/.pi/agent/mcp.json"
        temporary="$(mktemp "$mcp.tmp.XXXXXX")"
        ${lib.getExe pkgs.jq} --arg command '${lib.getExe cfg.package}' '
          .mcpServers."chrome-devtools".command = $command |
          .mcpServers."chrome-devtools".args = ["devtools", "--no-usage-statistics"]
        ' "$mcp" > "$temporary"
        chmod 0644 "$temporary"
        mv -f "$temporary" "$mcp"
      ''
    );
    wayland.windowManager.hyprland.lua.features.herdr-hypr = ''
      local function route(window)
        if window and window.class:match("^chromium%-agent%-%x+%-w%w+$") then
          hl.dispatch(hl.dsp.exec_cmd("${lib.getExe cfg.package} route " .. window.address))
        end
      end
      hl.on("window.open", route)
      -- Chromium can publish its final app_id after its first surface appears.
      hl.on("window.class", route)
    '';
  };
}
