{ pkgs, lib', ... }: let

  keymap = mode: key: action: {
    inherit mode key action;
    silent = true;
  };

  inherit (lib') nmap vmap imap;

in { 

  # Personal mappings
  vim.keymaps = [

    (imap "\\" "|" "Swap slash with pipe")
    (nmap "\\" "function() require('fzf-lua').buffers() end" "list buffers")

    # Enter command mode with semi-colon
    (nmap ";" ":" "Enter command mode")

    # Tab navigation 
    (nmap "<M-[>" ":tabprevious<CR>" "Previous tab")
    (nmap "<M-]>" ":tabnext<CR>" "Next tab")

    # wrapped lines goes down/up to next row, rather than next line in file
    (nmap "j" "gj" "Down a row")
    (nmap "k" "gk" "Up a row")

    # repeat indent/outdent
    (vmap "<" "<gv" "Outdent")
    (vmap ">" ">gv" "Indent")

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
