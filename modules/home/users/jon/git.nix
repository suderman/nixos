{...}: {
  programs.git = {
    enable = true;
    extraConfig.user = {
      name = "Jon Suderman";
      email = "jon@suderman.net";
    };
  };
}
