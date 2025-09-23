{
  config,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    extraConfig.user = {
      name = "Jon Suderman";
      email = "jon@suderman.net";
    };
  };
  age.secrets.git-credentials.rekeyFile = ./git-credentials.age;
  home.activation.git-credentials = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cat ${config.age.secrets.git-credentials.path} >${config.home.homeDirectory}/.git-credentials
  '';
}
