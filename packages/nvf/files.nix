{flake, ...}: let
  inherit (flake.lib) nmap mkLuaInline mkLuaCallback;
in {
  vim = {
    utility.oil-nvim.enable = true;
    utility.oil-nvim.setupOpts = {
      default_file_explorer = true;
      delete_to_trash = true;
      columns = ["icon" "permissions" "size" "mtime"];
      skip_confirm_for_simple_edits = true;
      view_options = {
        show_hidden = true;
        natural_order = true;
        is_always_hidden =
          mkLuaInline
          # lua
          ''
            function(name, _)
              return name == '..' or name == '.git'
            end
          '';
      };
      win_options.wrap = true;
    };

    utility.snacks-nvim.setupOpts.explorer = {
      enabled = true;
      replace_netrw = false;
      finder = "explorer";
    };

    keymaps = [
      (nmap "-" "<cmd>Oil<cr>" "Oil")
      (nmap "<leader>e" (mkLuaCallback "Snacks.explorer" {}) "File Explorer")
    ];

    utility.snacks-nvim.setupOpts.image = {
      enabled = true;
      force = true;
      inline = true;
    };

    # https://github.com/folke/snacks.nvim/blob/main/docs/bigfile.md
    utility.snacks-nvim.setupOpts.bigfile.enable = true;

    # https://github.com/keonly/nvf-config/blob/af0cabe84288798f018c70d411a23a0ebc9a2932/config/plugins/utility/yazi-nvim.nix
    utility.yazi-nvim = {
      enable = true;

      mappings = {
        openYazi = "<leader>-";
        openYaziDir = "<leader>cw";
        yaziToggle = "<C-y>";
      };

      setupOpts = {
        open_for_directories = true;
      };
    };
  };
}
