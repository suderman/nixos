# programs.antigravity-cli.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.antigravity-cli;
in {
  config = lib.mkIf cfg.enable {
    programs.antigravity-cli.package = lib.mkDefault perSystem.agents.antigravity-cli;

    # Prefer the managed CLI over an older nix profile install.
    home.file.".local/bin/agy" = lib.mkIf (cfg.package != null) {
      source = lib.getExe' cfg.package "agy";
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
