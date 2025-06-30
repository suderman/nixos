{ pkgs, lib, ... }: { 

  vim = {

    viAlias = true;
    vimAlias = true;

    startPlugins = [ "plenary-nvim" ];

    goose.enable = true;

    spellcheck.enable = true;
    autocomplete.nvim-cmp.enable = true;
    statusline.lualine.enable = true;
    # statusline.lualine.theme = "catppuccin";

    withPython3 = true;

    autopairs.nvim-autopairs.enable = true;

    lsp = {
      enable = true;
      formatOnSave = true;
      lspkind.enable = false;
      lightbulb.enable = true;
      lspsaga.enable = false;
      trouble.enable = true;
      lspSignature.enable = false;
      otter-nvim.enable = true;
      nvim-docs-view.enable = true;
    };

    snippets.luasnip.enable = true;


    filetree = {
      neo-tree.enable = true;
    };

    tabline = {
      nvimBufferline.enable = true;
    };


    treesitter.context.enable = true;

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
      hardtime-nvim.enable = false;
    };

    telescope.enable = true;

    git = {
      enable = true;
      gitsigns.enable = true;
      gitsigns.codeActions.enable = false; # throws an annoying debug message
    };

    minimap = {
      minimap-vim.enable = false;
      codewindow.enable = true; 
    };

    dashboard = {
      dashboard-nvim.enable = false;
      alpha.enable = true;
    };


    notify = {
      nvim-notify.enable = true;
    };

    projects = {
      project-nvim.enable = true;
    };


    utility = {
      ccc.enable = false;
      vim-wakatime.enable = false;
      diffview-nvim.enable = true;
      yanky-nvim.enable = false;
      icon-picker.enable = true;
      surround.enable = true;
      leetcode-nvim.enable = true;
      multicursors.enable = true;
      smart-splits.enable = true;
      motion = {
        hop.enable = true;
        leap.enable = true;
        precognition.enable = false; # annoying
      };
      images = {
        image-nvim.enable = false;
        img-clip.enable = true;
      };
    };

    notes = {
      obsidian.enable = false; 
      neorg.enable = false;
      orgmode.enable = false;
      mind-nvim.enable = false;
      todo-comments.enable = false;
    };

    terminal = {
      toggleterm = {
        enable = true;
        lazygit.enable = true;
      };
    };

    ui = {
      borders.enable = true;
      noice.enable = false;
      colorizer.enable = true;
      modes-nvim.enable = false; # the theme looks terrible with catppuccin
      illuminate.enable = true;
      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };
      smartcolumn = {
        enable = true;
        setupOpts.custom_colorcolumn = {
          # this is a freeform module, it's `buftype = int;` for configuring column position
          nix = "110";
          ruby = "120";
          java = "130";
          go = ["90" "130"];
        };
      };
      fastaction.enable = true;
    };

    assistant = {
      chatgpt.enable = false;
      copilot = {
        enable = true;
        cmp.enable = true;
      };
      codecompanion-nvim.enable = false;
      avante-nvim.enable = true;
    };

    session.nvim-session-manager.enable = false;
    gestures.gesture-nvim.enable = false;
    comments.comment-nvim.enable = true;
    presence.neocord.enable = false;

    languages = {
      enableFormat = true; 
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      markdown.enable = true;

      bash.enable = true;
      clang.enable = true;
      # css.enable = true;
      html.enable = true;
      sql.enable = true;
      java.enable = false;
      kotlin.enable = false;
      # ts.enable = true;
      go.enable = true;
      lua.enable = true;
      zig.enable = false;
      python.enable = true;
      typst.enable = false;
      rust = {
        enable = true;
        crates.enable = true;
      };

      assembly.enable = false;
      astro.enable = false;
      nu.enable = false;
      csharp.enable = false;
      julia.enable = false;
      vala.enable = false;
      scala.enable = false;
      r.enable = false;
      gleam.enable = false;
      dart.enable = false;
      ocaml.enable = false;
      elixir.enable = false;
      haskell.enable = false;
      ruby.enable = true;
      fsharp.enable = false;

      tailwind.enable = true;
      # svelte.enable = true;

      php = {
        enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
      # python = {
      #   enable = true;
      #   lsp.enable = true;
      #   format.enable = true;
      #   format.type = "ruff";
      #   treesitter.enable = true;
      # };
    };

    visuals = {
      nvim-scrollbar.enable = true;
      nvim-web-devicons.enable = true;
      nvim-cursorline.enable = true;
      cinnamon-nvim.enable = true;
      fidget-nvim.enable = true;

      highlight-undo.enable = true;
      indent-blankline.enable = true;

      # Fun
      cellular-automaton.enable = true;
    };


    clipboard = {
      enable = true;
      providers.xclip.enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamed";
    };

    options = {
      shiftwidth = 2;
      tabstop = 2;
    };

    keymaps = [
      {
        mode = "n";
        silent = true;
        key = ";";
        action = ":";
      }
    ];

    theme.extraConfig = ''
      vim.cmd([[
        " Visual shifting (builtin-repeat)
        vmap < <gv
        vmap > >gv

        " Better visual block selecting
        set virtualedit+=block
        set virtualedit+=insert
        set virtualedit+=onemore
      ]])
    '';

  };
}
