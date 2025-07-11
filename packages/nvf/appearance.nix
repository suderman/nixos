{
  lib,
  pkgs,
  flake,
  ...
}: let
  inherit (lib) mkForce;
  inherit (flake.lib) mkLuaInline;
in {
  vim.options.cursorlineopt = "line"; # line, screenline, number, both
  vim.options.breakindent = true; # indent wrapped lines to match line start
  vim.options.linebreak = true; # wrap long lines at 'breakat' (if 'wrap' is set)
  vim.options.number = true; # show line numbers
  vim.options.ruler = true; # show cursor position in command line
  vim.options.wrap = true; # display long lines as just one line
  vim.options.signcolumn = "yes"; # always show sign column (otherwise it will shift text)
  vim.options.fillchars = "eob: "; # don't show `~` outside of buffer
  vim.options.termguicolors = true; # enable gui colors

  vim.statusline.lualine.enable = true;
  vim.options.showmode = mkForce false; # show mode in command line

  # vim.mini.animate.enable = true;

  vim.theme.enable = true;
  vim.theme.transparent = true;

  vim.options.pumblend = 10; # make builtin completion menus slightly transparent
  vim.options.pumheight = 10; # make popup menu smaller
  vim.options.winblend = 10; # make floating windows slightly transparent

  vim.visuals.nvim-scrollbar.enable = true;
  vim.visuals.nvim-web-devicons.enable = true;
  vim.visuals.nvim-cursorline.enable = true;
  # vim.visuals.cinnamon-nvim.enable = true;
  vim.visuals.fidget-nvim.enable = true;
  vim.visuals.highlight-undo.enable = true;
  # vim.visuals.indent-blankline.enable = true;

  vim.ui.borders.enable = true;
  vim.ui.colorizer.enable = true;
  vim.ui.smartcolumn = {
    enable = true;
    setupOpts.custom_colorcolumn = {
      nix = "110";
      ruby = "120";
      java = "130";
      go = ["90" "130"];
    };
  };

  vim.utility.snacks-nvim.setupOpts.scroll = {
    enabled = true;
    animate.duration.step = 10;
    animate.duration.total = 200;
  };

  vim.utility.snacks-nvim.setupOpts.scope.enabled = true;
  vim.utility.snacks-nvim.setupOpts.dim = {
    enabled = true;
    animate.duration.step = 10;
    animate.duration.total = 200;
  };

  vim.utility.snacks-nvim.setupOpts.input.enabled = true;

  vim.utility.snacks-nvim.setupOpts.notifier = {
    enabled = true;
    level = "INFO";
    style = "minimal";
    top_down = false;
  };

  vim.extraPlugins = {
    "transparent.nvim" = {
      package = pkgs.vimPlugins.transparent-nvim;
      setup =
        # lua
        ''
          require("transparent").setup({
          	extra_groups = {
          		"NormalFloat",
          	},
          })
        '';
    };
  };
}
