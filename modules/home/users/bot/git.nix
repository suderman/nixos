{config, ...}: {
  programs.git = {
    enable = true;
    settings.user = {
      name = "suderbot";
      email = "jon@suderbot.net";
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
