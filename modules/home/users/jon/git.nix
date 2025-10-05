{config, ...}: {
  programs.git = {
    enable = true;
    extraConfig.user = {
      name = "Jon Suderman";
      email = "jon@suderman.net";
    };
  };

  age.secrets.git-credentials.rekeyFile = ./git-credentials.age;
  tmpfiles.files = [
    {
      target = ".git-credentials";
      source = config.age.secrets.git-credentials.path;
      mode = 600;
    }
  ];
}
