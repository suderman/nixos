{ flake, ... }: let
  inherit (flake.lib) mkLuaInline;
in {
  vim.undoFile.enable = true;
  vim.undoFile.path = mkLuaInline "vim.fn.stdpath('state') .. '/undo'";
}
