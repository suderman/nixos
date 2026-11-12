{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.herdr;

  edger = pkgs.self.mkScript {
    name = "edger";
    path = [cfg.package pkgs.jq pkgs.procps];
    text = builtins.readFile "${flake.inputs.edger}/bin/edger";
  };

  # A phone left attached (herdr-link attach) pins its pane to the phone's
  # size. Take over briefly, which ends that client, then let go so the pane
  # returns to its layout size.
  herdrReclaim = pkgs.self.mkScript {
    name = "herdr-reclaim";
    path = [cfg.package pkgs.jq pkgs.coreutils pkgs.util-linux];
    text =
      # bash
      ''
        pane=''${1:-''${HERDR_ACTIVE_PANE_ID:-}}
        [[ -n $pane ]] || { echo "usage: herdr-reclaim [PANE]" >&2; exit 2; }

        terminal=$(herdr pane get "$pane" | jq -er .result.pane.terminal_id)
        read -r rows cols < <(herdr pane layout --pane "$pane" |
          jq -er --arg p "$pane" '[.. | objects | select(.pane_id? == $p) | .rect][0] | "\(.height) \(.width)"')

        # The attach client needs a terminal and a stdin that stays open but
        # silent; end of input would reach the agent. Keybinds get /dev/null.
        sleep 5 | timeout 2 env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
          script -qec "stty rows $rows cols $cols; exec herdr terminal attach $terminal --takeover" /dev/null \
          >/dev/null 2>&1 || true
      '';
  };
in {
  config = lib.mkIf cfg.enable {
    # Editors still call the edger executable to cross into Herdr.
    home.packages = [edger herdrReclaim];

    # The keybindings below call this plugin; Termux installs it from GitHub.
    home.activation.edgerHerdrPlugin = lib.mkIf (cfg.package != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${lib.getExe cfg.package} plugin link ${flake.inputs.edger} >/dev/null
      ''
    );

    # Home Manager owns config.toml, so Herdr cannot record onboarding itself.
    programs.herdr.settings = {
      onboarding = false;
      ui = {
        toast.delivery = "herdr";
        sidebar.spaces.rows = [["state_icon" "workspace" "branch"]];
        prompt_new_tab_name = false;
      };

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

        # Edger's plugin actions carry no Nix-store paths, so the phone shares
        # these bindings. They forward Alt keys, edger's default modifier.
        command = let
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
          edgerAction = key: action: description: {
            inherit key description;
            type = "plugin_action";
            command = "edger.${action}";
          };
        in
          lib.mapAttrsToList (direction: letter:
            edgerAction "alt+${letter}" direction "Navigate ${direction} across editor, pane, and outer layer")
          binds.direction
          ++ lib.mapAttrsToList (direction: letter:
            edgerAction "alt+shift+${letter}" "resize-${direction}" "Resize ${direction} across editor and pane")
          binds.direction
          ++ lib.mapAttrsToList (action: letter: edgerAction "alt+${letter}" action "Edger ${action}")
          binds.action
          ++ [
            {
              key = "prefix+t";
              type = "shell";
              command = lib.getExe herdrReclaim;
              description = "Take the pane back from a phone attach";
            }
          ];
      };
    };
  };
}
