{...}: {
  config = {
    programs.git = {
      enable = true;
      settings.user = {
        name = "suderbot";
        email = "jon@suderbot.net";
      };
    };
    programs.gh = {
      enable = true;
      token = ./gh-token.age;
    };
  };
}
