{...}: {
  programs.ssh = {
    settings = {
      # Termux on GrapheneOS.
      gem = {
        User = "jon";
        HostName = "gem.tail";
        Port = 8022;
      };

      # Personal droplet.
      toronto = {
        User = "suderman";
        HostName = "toronto.suderman.net";
      };
    };
  };
}
