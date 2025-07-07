{ pkgs, lib, utility, ... }: let

  inherit (lib.generators) mkLuaInline; 

  fzfMap = key: fzfCommand: desc: {
    inherit key desc;
    action = ":FzfLua ${fzfCommand}<CR>";
    mode = "n";
    silent = true;
  };

in {

  vim.fzf-lua = {
    enable = true;
    # profile = "default";
    setupOpts = {
      "@1" = "ivy";
      fzf_bin = "${pkgs.fzf.out}/bin/fzf";
    };
  };
  
  vim.keymaps = [

    { 
      mode = "n";
      silent = true;
      key = "<C-p>"; 
      action = "function() require('fzf-lua').buffers() end";
      lua = true;
      desc = "Find files";
    }

    (fzfMap "<leader>ff" "files" "[F]ind [F]iles")
    (fzfMap "<C-f>" "files" "[F]ind [F]iles")
    (fzfMap "<leader>fb" "buffers" "[F]ind [B]uffers")
    (fzfMap "<leader>fg" "live_grep" "[F]ind by [G]rep")
    (fzfMap "<C-g>" "live_grep" "[F]ind by [G]rep")
    (fzfMap "<leader>fk" "keymaps" "[F]ind [K]eymap")
  ];

  vim.lazy.plugins.bufexplorer = {
    package = pkgs.vimPlugins.bufexplorer;
  };

  # Shift-K toggles buffer explorer
  vim.luaConfigRC.bufexplorer = ''
    vim.api.nvim_create_user_command("BufExplorerBuffers", function()
      local title = vim.fn.expand("%:t")
      if title == "[BufExplorer]" then
        vim.cmd("b#")
      else
        vim.cmd("silent BufExplorer")
      end
    end, {})
    vim.keymap.set("n", "<S-k>", ":BufExplorerBuffers<CR>", { silent = true })
  '';

}
