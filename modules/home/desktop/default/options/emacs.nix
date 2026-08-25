# programs.emacs.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.emacs;
  inherit (lib) mkDefault mkIf;
  configDir = ".config/emacs";
  # Prefer a writable checkout without losing the flake's bundled fallback.
  emacsPackage = pkgs.symlinkJoin {
    inherit (perSystem.emacs.default) name meta;
    paths = [perSystem.emacs.default];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/emacs" \
        --run 'config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/emacs"; if [ -f "$config_dir/init.el" ]; then set -- --init-directory "$config_dir" "$@"; fi'
    '';
  };
in {
  config = mkIf cfg.enable {
    programs.emacs.package = mkDefault emacsPackage;

    services.emacs = {
      enable = mkDefault true;
      client.enable = mkDefault true;
      defaultEditor = mkDefault true;
      startWithUserSession = mkDefault "graphical";
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
