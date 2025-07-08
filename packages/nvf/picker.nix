{ pkgs, lib, lib', ... }: let
  inherit (lib.generators) mkLuaInline; 
in {

  vim.telescope = {
    enable = true;

    extensions = [
      { 
        name = "fzf"; 
        packages = [ pkgs.vimPlugins.telescope-fzf-native-nvim ];
        setup.fzf = { 
          fuzzy = true; # false will only do exact matching
          override_generic_sorter = true; # override the generic sorter
          override_file_sorter = true; # override the file sorter
          case_mode = "smart_case"; # ignore_case respect_case
        }; 
      }
      { 
        name = "frecency"; 
        packages = [ pkgs.vimPlugins.telescope-frecency-nvim ];
        setup.frecency = {}; 
      }
    ];

    mappings = {
      # buffers = "<leader>fb";
      buffers = "K";
      diagnostics = "<leader>fld";
      # findFiles = "<leader>ff";
      findFiles = "<C-f>";
      findProjects = "<leader>fp";
      gitBranches = "<leader>fvb";
      gitBufferCommits = "<leader>fvcb";
      gitCommits = "<leader>fvcw";
      gitStash = "<leader>fvx";
      gitStatus = "<leader>fvs";
      helpTags = "<leader>fh";
      # liveGrep = "<leader>fg";
      liveGrep = "<C-k>";
      lspDefinitions = "<leader>flD";
      lspDocumentSymbols = "<leader>flsb";
      lspImplementations = "<leader>fli";
      lspReferences = "<leader>flr";
      lspTypeDefinitions = "<leader>flt";
      lspWorkspaceSymbols = "<leader>flsw";
      # open = "<leader>ft";
      open = "<C-t>";
      resume = "<leader>fr";
      treesitter = "<leader>fs";
    };

    setupOpts.defaults = {
      color_devions = false;
      entry_prefix = " ";
      extensions = {};
      file_ignore_patterns = [
        "node_modules"
        "%.git/"
        "dist/"
        "build/"
        "target/"
        "result/"
      ];
      initial_mode = "insert"; # normal
      layout_config = {
        height = 0.8;
        width = 0.8;
        horizontal.preview_width = 0.55;
        horizontal.prompt_position = "top"; # bottom
        vertical.mirror = false;
        preview_cutoff = 120;
      };
      layout_strategy = "horizontal"; # vertical center cursor flex
      path_display = [ "absolute" ]; # hidden tail smart shorten truncate
      pickers.find_command = [ "${pkgs.fd}/bin/fd" ];
      prompt_prefix = "  ";
      selection_caret = " ";
      selection_strategy = "reset"; # follow row closest none
      set_env.COLORTERM = "truecolor";
      sorting_strategy = "ascending"; # descending
      vimgrep_arguments = [
        "${pkgs.ripgrep}/bin/rg"
        "--color=never"
        "--no-heading"
        "--with-filename"
        "--line-number"
        "--column"
        "--smart-case"
        "--hidden"
        "--no-ignore"
      ];
      winblend = 0;
    };

    setupOpts.pickers.find_files.find_command = [
      "${pkgs.fd}/bin/fd"
      "--type=file"
    ];

    setupOpts.pickers.buffers = {
      initial_mode = "normal";
      layout_strategy = "center";
      path_display = [ "smart" ]; 
      prompt_prefix = " 󰈚 ";
      selection_caret = "▸";
      selection_strategy = "follow";
      sort_mru = true; 
      mappings.n = mkLuaInline ''{ 
        ["K"] = require('telescope.actions').close, 
        ["J"] = require('telescope.actions').close, 
        ["d"] = require("telescope.actions").delete_buffer,
      }'';
    };

  };

  # vim.lazy.plugins.bufexplorer = {
  #   package = pkgs.vimPlugins.bufexplorer;
  # };
  #
  # # Shift-K toggles buffer explorer
  # vim.luaConfigRC.bufexplorer = ''
  #   vim.api.nvim_create_user_command("BufExplorerBuffers", function()
  #     local title = vim.fn.expand("%:t")
  #     if title == "[BufExplorer]" then
  #       vim.cmd("b#")
  #     else
  #       vim.cmd("silent BufExplorer")
  #     end
  #   end, {})
  #   vim.keymap.set("n", "<S-k>", ":BufExplorerBuffers<CR>", { silent = true })
  # '';

  # vim.fzf-lua = {
  #   enable = false;
  #   # profile = "fzf-native";
  #   # profile = "default";
  #   # profile = "borderless";
  #   setupOpts = {
  #     # "@1" = "ivy";
  #     fzf_bin = "${pkgs.fzf.out}/bin/fzf";
  #     # fzf_bin = "nil";
  #     winopts.border = "none";
  #     winopts.backdrop = 100;
  #     winopts.split = "belowright new";
  #     winopts.preview.default = "bat";
  #     winopts.preview.border = "noborder";
  #   };
  # };
  #
  # vim.keymaps = [
  #
  #   # { 
  #   #   mode = "n";
  #   #   silent = true;
  #   #   key = "<C-p>"; 
  #   #   action = "function() require('fzf-lua').buffers() end";
  #   #   lua = true;
  #   #   desc = "Find files";
  #   # }
  #   #
  #   # (fzfMap "<leader>ff" "files" "[F]ind [F]iles")
  #   # (fzfMap "<C-f>" "files" "[F]ind [F]iles")
  #   # (fzfMap "<leader>fb" "buffers" "[F]ind [B]uffers")
  #   # (fzfMap "<leader>fg" "live_grep" "[F]ind by [G]rep")
  #   # (fzfMap "<C-g>" "live_grep" "[F]ind by [G]rep")
  #   # (fzfMap "<leader>fk" "keymaps" "[F]ind [K]eymap")
  # ];
  # fzfMap = key: fzfCommand: desc: {
  #   inherit key desc;
  #   action = ":FzfLua ${fzfCommand}<CR>";
  #   mode = "n";
  #   silent = true;
  # };


}
