{ pkgs, lib, ... }: { 

  vim.keymaps = [
    { mode = "n"; key = ";"; action = ":"; silent = true; }
    { mode = "v"; key = "<"; action = "<gv"; silent = true; }
    { mode = "v"; key = ">"; action = ">gv"; silent = true; }
  ];

  vim.utility.smart-splits = {
    enable = true;
    keymaps = {
      resize_left = "<A-H>";
      resize_down = "<A-J>";
      resize_up = "<A-K>";
      resize_right = "<A-L>";
      move_cursor_left = "<A-h>";
      move_cursor_down = "<A-j>";
      move_cursor_up = "<A-k>";
      move_cursor_right = "<A-l>";
    };
  };

}
