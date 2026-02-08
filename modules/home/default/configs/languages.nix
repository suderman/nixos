{lib, ...}: {
  programs.javascript.enable = lib.mkDefault true;
  programs.lua.enable = lib.mkDefault true;
  programs.php.enable = lib.mkDefault true;
  programs.python.enable = lib.mkDefault true;
  programs.ruby.enable = lib.mkDefault true;
}
