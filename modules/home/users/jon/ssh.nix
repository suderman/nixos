{...}: {
  programs.ssh = {
    matchBlocks = {
      # Termux on GrapheneOS.
      gem = {
        user = "jon";
        hostname = "gem.tail";
        port = 8022;
      };

      # Personal droplet.
      toronto = {
        user = "suderman";
        hostname = "toronto.suderman.net";
      };
    };
  };
}
