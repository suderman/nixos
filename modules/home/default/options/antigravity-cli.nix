# programs.antigravity-cli.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.antigravity-cli;
in {
  config = lib.mkIf cfg.enable {
    programs.antigravity-cli.package = lib.mkDefault perSystem.agents.antigravity-cli;

    # Prefer the managed CLI over an older nix profile install.
    home.file.".local/bin/agy" = lib.mkIf (cfg.package != null) {
      source = lib.getExe (pkgs.self.mkScript {
        name = "agy";
        text = ''
          for arg in "$@"; do
            case "$arg" in
              --mode|--mode=*|--settings|--settings=*|--sandbox|--dangerously-skip-permissions)
                exec ${lib.getExe' cfg.package "agy"} "$@" ;;
              --) break ;;
            esac
          done
          exec ${lib.getExe' cfg.package "agy"} --dangerously-skip-permissions "$@"
        '';
      });
    };

    # Keep auth and sessions private. The CLI and agents apply own their writable configuration.
    persist.storage.directories = [
      {
        directory = ".gemini";
        mode = "0700";
      }
      {
        directory = ".config/antigravity";
        mode = "0700";
      }
    ];
  };
}
