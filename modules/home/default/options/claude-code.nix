# programs.claude-code.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: {
  # Extend Home Manager's package integration without declaring runtime files.
  programs.claude-code.package = lib.mkDefault perSystem.agents.claude-code;

  persist.storage = lib.mkIf config.programs.claude-code.enable {
    directories = [
      {
        directory = ".claude";
        mode = "0700";
      }
    ];
    files = [".claude.json"];
  };
}
