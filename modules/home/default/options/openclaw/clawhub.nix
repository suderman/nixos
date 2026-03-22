# config.programs.openclaw.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.openclaw;

  clawhub-wrapper = pkgs.self.mkScript {
    name = "clawhub";
    text =
      # bash
      ''
        export SKILLS_DIR="''${SKILLS_DIR:-${config.home.homeDirectory}/workspace/all/clawhub}"
        export CLAWHUB_BIN="''${CLAWHUB_BIN:-${config.home.homeDirectory}/.local/share/npm/bin/clawhub}"

        # Initizalize OpenClaw: install via npm and create a ready gateway config with secrets
        clawhub_init() {

          # Install/update openclaw globally
          # npm already enabled via toolchains.javascript.enable = true;
          npm i -g clawhub

          # Ensure OpenClaw is actually installed
          if [[ ! -f $CLAWHUB_BIN ]]; then
            echo "Failed to install clawhub"
            exit 1
          fi

          mkdir -p $SKILLS_DIR

        }

        # Change default command to update all
        [[ "$#" -eq 0 ]] && set -- update --all --force

        # Avoid skill leakage
        if [[ "''${1-}" == "publish" ]]; then
          echo "Disabled command"

        # Avoid skill leakage
        elif [[ "''${1-}" == "sync" ]]; then
          echo "Disabled command"

        # If argument is "init", run the above script
        elif [[ "''${1-}" == "init" ]]; then
          clawhub_init

        # Else, if the config or binary is missing, run the above script first
        elif [[ ! -e $SKILLS_DIR ]] || [[ ! -e $CLAWHUB_BIN ]]; then
          clawhub_init
          $CLAWHUB_BIN --dir "$SKILLS_DIR" "$@"

        # Otherwise, just passthrough to openclaw
        else
          $CLAWHUB_BIN  --dir "$SKILLS_DIR" "$@"
        fi
      '';
  };
in {
  config = lib.mkIf cfg.enable {
    # Install clawhub from npm and run with nodejs
    toolchains.javascript.enable = true;

    # Persist login
    persist.storage.directories = [".config/clawhub"];

    # Add clawhub wrapper to user path (higher priority than npm)
    home.file = {
      ".local/bin/clawhub".source = "${clawhub-wrapper}/bin/clawhub";
      ".local/bin/clawdhub".source = "${clawhub-wrapper}/bin/clawhub";
    };
  };
}
