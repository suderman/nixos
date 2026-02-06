{...}: {
  config = {
    programs.git = {
      enable = true;
      settings.user = {
        name = "Jon Suderman";
        email = "jon@suderman.net";
      };
    };
    programs.gh = {
      enable = true;
      token = ./gh-token.age;
    };
  };
}
