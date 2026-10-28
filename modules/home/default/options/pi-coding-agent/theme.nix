{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  agentDir = ".pi/agent";

  piStylixTheme = pkgs.self.mkScript {
    name = "pi-stylix-theme";
    path = [pkgs.coreutils];
    text = let
      palette = config.lib.stylix.colors.withHashtag;
      template = builtins.fromJSON (builtins.readFile "${flake.inputs.agents}/pi/themes/catppuccin-mocha.json");
      theme = pkgs.writeText "pi-stylix-theme.json" (builtins.toJSON (template
        // {
          name = "stylix";
          vars = {
            bg = palette.base00;
            panel = palette.base00;
            panelAlt = palette.base00;
            selected = palette.base01;
            border = palette.base02;
            accent = palette.base0D;
            cyan = palette.base0C;
            green = palette.base0B;
            red = palette.base08;
            yellow = palette.base0A;
            orange = palette.base09;
            purple = palette.base0E;
            text = palette.base05;
            muted = palette.base04;
            dim = palette.base03;
            toolSuccessBg = palette.base01;
            toolErrorBg = palette.base01;
          };
          export = {
            pageBg = "bg";
            cardBg = "panel";
            infoBg = "selected";
          };
        }));
    in ''
      target_dir="''${PI_CODING_AGENT_DIR:-${config.home.homeDirectory}/${agentDir}}/themes"
      target="$target_dir/stylix.json"
      if [[ ! -L "$target" && -f "$target" && -w "$target" ]] && cmp -s ${theme} "$target"; then
        exit 0
      fi
      mkdir -p -- "$target_dir"
      temporary="$(mktemp "$target.tmp.XXXXXX")"
      trap 'rm -f -- "$temporary"' EXIT
      cp -- ${theme} "$temporary"
      chmod 0644 -- "$temporary"
      mv -fT -- "$temporary" "$target"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    # Preserve writable Pi theme files; bootstrap leaves this generated entry alone.
    home.activation.piStylixTheme = lib.mkIf config.stylix.enable (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${lib.getExe piStylixTheme}
      ''
    );
  };
}
