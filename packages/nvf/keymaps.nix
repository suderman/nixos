{ pkgs, lib, ... }: let

  keymap = mode: key: action: {
    inherit mode key action;
    silent = true;
  };

in { 

  # Personal mappings
  vim.keymaps = [

    # Enter command mode with semi-colon
    (keymap "n" ";" ":")

    # Tab navigation 
    (keymap "n" "<M-[>" ":tabprevious<CR>")
    (keymap "n" "<M-]>" ":tabnext<CR>")

    # wrapped lines goes down/up to next row, rather than next line in file
    (keymap "n" "j" "gj")
    (keymap "n" "k" "gk")

    # repeat indent/outdent
    (keymap "v" "<" "<gv")
    (keymap "v" ">" ">gv")

  ];

  # [b]uffer
  # [c]omment
  # [x]conflict
  # [d]iagnostic
  # [f]ile
  # [i]ndent
  # [j]ump
  # [l]ocation
  # [o]ldfile
  # [q]uickfix
  # [t]reesitter
  # [u]ndo
  # [w]indow
  # [y]ank
  vim.mini.bracketed.enable = true;

  vim.comments.comment-nvim.enable = true;

}
