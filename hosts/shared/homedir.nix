{ host, lib, ... }:

let 
  inherit (host) hostname username system;
  kernel = lib.lists.head (lib.lists.tail (lib.strings.splitString "-" system));
  homedir = if (kernel == "darwin") then "/Users/${username}" else "/home/${username}";

in homedir
