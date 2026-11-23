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
    # June's numbered logins (codex1, codex2, ...) run Codex from here, since she holds the codex name in ~/.local/bin.
    home.file.".local/libexec/june/codex" = lib.mkIf (config.programs.june.accounts.enable or false) {
      source = lib.getExe config.programs.codex.package;
    };
  };
}
