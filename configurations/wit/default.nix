{
  host = "wit"; 
  domain = "suderman.org"; 
  user = "me"; 
  system = "x86_64-linux";
  config = {
    modules.secrets.enable = true;
    modules.gnome.enable = true;
  };
}
