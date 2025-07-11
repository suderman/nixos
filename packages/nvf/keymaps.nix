{flake, ...}: let
  inherit (flake.lib) nmap vmap;
in {
  vim.keymaps = [
    # Prevent spacebar from doing anything on its own
    (nmap "<leader>" "<nop>" "No operation")

    # Enter command mode with semi-colon
    (nmap ";" ":" "Enter command mode")

    # Clear highlighted search
    (nmap "<leader>c" ":noh<CR>:match none<CR>:2match none<CR>:3match none<CR>" "Clear search")

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
