{pkgs, ...}: {
  home.packages = with pkgs; [
    yo # example script
    self.fetchgithub # fetch hash from repo
    self.shizuku # connect android to pc and run
  ];

  # Aliases
  home.shellAliases = {
    neofetch = "fastfetch";
  };
}
