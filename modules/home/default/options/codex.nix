# programs.codex.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.programs.codex.enable {
    programs.codex.package = lib.mkDefault pkgs.unstable.codex;

    # Keep Codex and agents apply on the same writable home, even with XDG defaults enabled.
    home.sessionVariables.CODEX_HOME = lib.mkForce "${config.home.homeDirectory}/.codex";
    persist.storage.directories = [
      {
        directory = ".codex";
        mode = "0700";
      }
    ];
  };
}
