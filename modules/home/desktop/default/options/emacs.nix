# programs.emacs.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.emacs;
  inherit (lib) mkDefault mkIf;
  configDir = ".config/emacs";
in {
  config = mkIf cfg.enable {
    programs.emacs = {
      package = mkDefault pkgs.emacs-pgtk;

      # Keep pure Elisp and day-to-day package iteration in mutable Emacs land.
      # Nix owns native/problematic packages and grammar libraries.
      extraPackages = epkgs:
        with epkgs; [
          vterm
          pdf-tools
          jinx
          treesit-auto
          treesit-grammars.with-all-grammars

          # Language modes missing from core, or useful for non-core formats.
          lua-mode
          markdown-ts-mode
          nix-ts-mode
          php-mode
          web-mode
        ];
    };

    services.emacs = {
      enable = mkDefault true;
      client.enable = mkDefault true;
      defaultEditor = mkDefault true;
      startWithUserSession = mkDefault "graphical";
      extraOptions = mkDefault [
        "--init-directory"
        "${config.xdg.configHome}/emacs"
      ];
    };

    home.packages = with pkgs; [
      # Search/navigation helpers Emacs packages commonly shell out to.
      fd
      ripgrep

      # Spellchecking substrate for ispell/flyspell/jinx.
      enchant
      hunspell
      hunspellDicts.en_US

      # LSP servers for common desktop/editor work.
      bash-language-server
      basedpyright
      clang-tools
      gopls
      lua-language-server
      marksman
      nil
      phpactor
      ruby-lsp
      rust-analyzer
      taplo
      tree-sitter
      twig-language-server
      typescript-language-server
      vscode-langservers-extracted
      yaml-language-server

      # Formatters and linters.
      alejandra
      prettier
      ruff
      shellcheck
      shfmt
      stylua
      yamlfmt

      # previews and conversions
      pandoc
    ];

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
