# programs.emacs.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.emacs;
  inherit (lib) mkDefault mkIf;
  configDir = ".config/emacs";
in {
  config = mkIf cfg.enable {
    programs.emacs.package = mkDefault perSystem.emacs.default;

    services.emacs = {
      enable = mkDefault true;
      client.enable = mkDefault true;
      defaultEditor = mkDefault true;
      startWithUserSession = mkDefault "graphical";
      # The package defaults to its pinned config; the host daemon uses the checkout.
      extraOptions = mkDefault [
        "--init-directory"
        "${config.xdg.configHome}/emacs"
      ];
    };

    # keyboard shortcuts
    services.keyd.windows."emacs" = {
      "super.w" = "macro(C-x 0)"; # close window or tab
      "super.t" = "macro(C-x t 2)"; # new tab
      "super.r" = "f5"; # reload
    };

    # tui emacs
    home.shellAliases.em = "emacsclient --tty";

    # Native build tools for vterm, modules, and day-to-day Emacs experiments.
    toolchains.native.enable = true;

    # Mutable Emacs config belongs in storage with snapshots/backups.
    persist.storage.directories = [configDir];

    # Mutable package/state data should survive reboot without snapshots/backups.
    persist.scratch.directories = [
      ".local/share/emacs"
      ".local/state/emacs"
    ];
  };
}
