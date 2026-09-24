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
    home.packages = [cfg.package edger];

    # Herdr stores mutable local data beside Home Manager's generated config.toml.
    persist.storage.directories = [".config/herdr"];

    # Home Manager owns config.toml, so Herdr cannot record onboarding itself.
    programs.herdr.settings = {
      
      onboarding = false;
      ui.toast.delivery = "herdr";

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
          }) binds.direction
          
          ++ lib.mapAttrsToList (direction: letter: {
            key = "${modifier}+shift+${letter}";
            type = "shell";
            command = "${lib.getExe edger} resize ${direction} ${modifier}+shift+${letter}";
            description = "Navigate ${direction} across editor, pane, and outer layer";
          }) binds.direction
          
          ++ lib.mapAttrsToList (action: letter: {
            key = "${modifier}+${letter}";
            type = "shell";
            command = "${lib.getExe edger} ${action} ${modifier}+${letter}";
            description = "Edger ${action}";
          }) binds.action;
      };
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "herdr-config.toml" cfg.settings;
      onChange = "${cfg.package} server reload-config || true";
    };
  };
}
