{pkgs, ...}: {
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
    programs.tea = {
      enable = true;
      token = ./fj-token.age;
      host = "git.kit";
      user = "suderman";
    };
  };
}
