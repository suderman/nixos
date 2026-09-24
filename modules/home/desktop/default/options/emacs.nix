# programs.emacs.enable = true;
{
  config,
  lib,
  perSystem,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.programs.emacs;
  inherit (lib) mkDefault mkIf;
  configDir = ".config/emacs";
  fonts = config.stylix.fonts;
  paletteKeys = map (suffix: "base${suffix}") ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F"];
  # Resolve both schemes with the same Base16 parser and overrides as Stylix.
  palette = scheme: let
    colors = (config.stylix.base16.mkSchemeAttrs scheme).override config.stylix.override;
  in "(${lib.concatMapStringsSep "\n                 " (key: ":${key} ${builtins.toJSON colors.withHashtag.${key}}") paletteKeys})";
  schemes = osConfig.programs.stylix-theme-toggle;
  style = pkgs.writeText "emacs-style.el" ''
    ;;; style.el --- Generated from Nix/Stylix. Do not edit. -*- lexical-binding: t; -*-
    (setq suderman/system-style
          '(:mono-font ${builtins.toJSON fonts.monospace.name}
            :fallback-font "Ioskeley Mono"
            :variable-font ${builtins.toJSON fonts.serif.name}
            :icon-font "Symbols Nerd Font Mono"
            :font-size ${toString (fonts.sizes.terminal * 1.0)}
            :palettes (:light ${palette schemes.lightScheme}
                       :dark ${palette schemes.darkScheme})))
  '';
  # Syncthing needs portable contents, not a /nix/store symlink. Rename atomically.
  exportStyle = pkgs.writeShellScript "export-emacs-style" ''
    set -eu
    dest="$HOME/org/.generated/emacs/style.el"
    mkdir -p "$(dirname "$dest")"
    if [ ! -L "$dest" ] && cmp -s ${style} "$dest"; then
      exit 0
    fi
    tmp=$(mktemp "$dest.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    cp ${style} "$tmp"
    chmod 644 "$tmp"
    mv -fT "$tmp" "$dest"
  '';
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
  terminalSetup = ''
    if [[ "''${TERM-}" == xterm-256color && ( -n "''${SSH_TTY-}" || "''${COLORTERM-}" == truecolor ) ]]; then
      export TERM=xterm-direct2
    elif [[ "''${TERM-}" == tmux-256color && "''${COLORTERM-}" == truecolor ]]; then
      export TERM=tmux-direct
    fi
  '';
  terminalEditor = pkgs.writeShellScript "emacs-editor" ''
    ${terminalSetup}
    exec ${lib.getBin cfg.finalPackage}/bin/emacs --no-window-system "$@"
  '';
  workspaceClient = pkgs.writeShellApplication {
    name = "em-workspace-client";
    runtimeInputs = [cfg.finalPackage config.programs.herdr.package pkgs.tmux pkgs.jq pkgs.coreutils pkgs.util-linux];
    text = ''
      ${terminalSetup}
      EMACS_CLIENT=${lib.getBin cfg.finalPackage}/bin/emacsclient
      EMACS_SERVER=${lib.getBin cfg.finalPackage}/bin/emacs
      ${builtins.readFile ./emacs-workspace-client.sh}
    '';
  };
in {
  options.programs.emacs.exportStyle = lib.mkEnableOption "exporting shared Emacs appearance to the synced Org tree (enable on one host only)";

  config = mkIf cfg.enable {
    home.activation.emacsStyle = mkIf cfg.exportStyle (lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${exportStyle}
    '');
    programs.emacs.package = mkDefault emacsPackage;
    # Shared Lisp owns both variants and follows toolkit-theme on both platforms.
    stylix.targets.emacs.enable = false;
    programs.emacs.extraPackages = epkgs: [epkgs.base16-theme];

    services.emacs = {
      enable = mkDefault true;
      client.enable = mkDefault true;
      startWithUserSession = mkDefault "graphical";
    };

    home.sessionVariables = {
      EDITOR = terminalEditor;
      VISUAL = terminalEditor;
    };

    # keyboard shortcuts
    services.keyd.windows."emacs" = {
      "super.w" = "macro(C-x 0)"; # close window or tab
      "super.t" = "macro(C-x t 2)"; # new tab
      "super.r" = "f5"; # reload
    };

    # Disconnecting em's client keeps its daemon. In that frame,
    # M-x save-buffers-kill-emacs shuts it down with Emacs's save prompts.
    home.shellAliases = {
      em = "${lib.getExe workspaceClient}";
      ema = "${terminalEditor}";
      emd = ''${terminalEditor} --init-directory "$PWD"'';
    };

    # Native build tools for Emacs modules and day-to-day experiments.
    toolchains.native.enable = true;

    # Mutable Emacs config belongs in storage with snapshots/backups.
    persist.storage.directories = [configDir];

    # Mutable package/state data should survive reboot without snapshots/backups.
    persist.scratch.directories = [
      ".local/share/emacs"
      ".local/state/emacs"
      ".local/state/emacs-workspaces"
    ];
  };
}
