{
  pkgs,
  flake,
  ...
}: let
  inherit (flake.lib) nmap mkLuaCallback mkLuaInline;
in {
  vim.utility.snacks-nvim.enable = true;
  vim.utility.snacks-nvim.setupOpts.styles.notification.wo.wrap = true;

  vim.utility.snacks-nvim.setupOpts.picker = {
    enabled = true;
    layout.cycle = false;

    win.input.keys = {
      "s" = {
        "@1" = "flash";
        "mode" = ["n"];
      };
      "<c-s>" = {
        "@1" = "flash";
        "mode" = ["i"];
      };
    };

    actions.flash =
      mkLuaInline #lua
      
      ''
         function(picker)
           require("flash").jump({
             pattern = "^",
             label = { after = { 0, 0 } },
             search = {
               mode = "search",
               exclude = {
                 function(win)
                   return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                end,
               },
             },
             action = function(match)
               local idx = picker.list:row2idx(match.pos[1])
               picker.list:_move(idx, true, true)
            end,
           })
        end
      '';
  };

  vim.keymaps = [
    (nmap "<leader><space>" (mkLuaCallback "Snacks.picker.pick" {
      source = "smart";
    }) "Smart Find Files")

    (nmap "<leader>/" (mkLuaCallback "Snacks.picker.pick" {
      source = "grep";
    }) "Grep")

    (nmap "<leader>;" (mkLuaCallback "Snacks.picker.pick" {
      source = "command_history";
    }) "Command History")

    (nmap "<leader>n" (mkLuaCallback "Snacks.picker.pick" {
      source = "notifications";
    }) "Notification History")

    (nmap "<leader>p" (mkLuaCallback "Snacks.picker" {}) "Pickers")
  ];

  vim.extraPackages = with pkgs; [
    fd
    ghostscript
    git
    imagemagick
    lazygit
    mermaid-cli
    ripgrep
    sqlite
    tectonic
  ];
}
