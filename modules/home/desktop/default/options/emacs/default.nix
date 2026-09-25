{
  config,
  lib,
  perSystem,
  osConfig,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf concatMapStringsSep;
  cfg = config.programs.emacs;

  # Use a writable checkout when one exists; otherwise use the bundled config.
  emacsPackage = pkgs.symlinkJoin {
    inherit (perSystem.emacs.default) name meta;
    paths = [perSystem.emacs.default];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/emacs" \
        --run 'config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/emacs"; if [ -f "$config_dir/init.el" ]; then set -- --init-directory "$config_dir" "$@"; fi'
    '';
  };

  terminalEditor = pkgs.writeShellScript "emacs-editor" ''
    ${builtins.readFile ./terminal-setup.sh}
    exec ${lib.getBin cfg.finalPackage}/bin/emacs --no-window-system "$@"
  '';

  workspaceClient = pkgs.writeShellApplication {
    name = "em-workspace-client";
    runtimeInputs = [cfg.finalPackage config.programs.herdr.package pkgs.tmux pkgs.jq pkgs.coreutils pkgs.util-linux];
    text = ''
      ${builtins.readFile ./terminal-setup.sh}
      EMACS_CLIENT=${lib.getBin cfg.finalPackage}/bin/emacsclient
      EMACS_SERVER=${lib.getBin cfg.finalPackage}/bin/emacs
      ${builtins.readFile ./emacs-workspace-client.sh}
    '';
  };
in {
  options.programs.emacs.exportStyle = lib.mkEnableOption "exporting shared Emacs appearance to the synced Org tree (enable on one host only)";

  config = mkIf cfg.enable {
    home.activation.emacsStyle = let
      fonts = config.stylix.fonts;
      schemes = osConfig.programs.stylix-theme-toggle;

      # Use Stylix's scheme parser and overrides for both light and dark palettes.
      palette = scheme: let
        inherit (builtins) toJSON;
        colors = (config.stylix.base16.mkSchemeAttrs scheme).override config.stylix.override;
        spacer = "\n                 ";
        paletteKeys = map (suffix: "base${suffix}") ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F"];
      in "(${concatMapStringsSep spacer (key: ":${key} ${toJSON colors.withHashtag.${key}}") paletteKeys})";

      style = pkgs.writeText "emacs-style.el"
        # elisp
        ''
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

      exportStyle = pkgs.writeShellScript "export-emacs-style" ''
        style=${style}
        ${builtins.readFile ./export-style.sh}
      '';
    in mkIf cfg.exportStyle (lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${exportStyle}
    '');

    programs.emacs.package = mkDefault emacsPackage;
    programs.emacs.extraPackages = epkgs: [epkgs.base16-theme];

    # Emacs loads the generated palettes itself and follows toolkit-theme changes.
    stylix.targets.emacs.enable = false;

    services.emacs = {
      enable = mkDefault true;
      client.enable = mkDefault true;
      startWithUserSession = mkDefault "graphical";
    };

    home.sessionVariables = {
      EDITOR = terminalEditor;
      VISUAL = terminalEditor;
    };

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

    toolchains.native.enable = true;

    # Back up the config, but keep package and runtime state in scratch storage.
    persist.storage.directories = [".config/emacs"];
    persist.scratch.directories = [
      ".local/share/emacs"
      ".local/state/emacs"
      ".local/state/emacs-workspaces"
    ];
  };
}
