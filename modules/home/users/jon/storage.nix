{
  config,
  lib,
  ...
}: {
  xdg.userDirs = with config.home; {
    documents = "${storageDirectory}/docs";
    music = "${storageDirectory}/music";
    pictures = "${storageDirectory}/pics";
    videos = "${storageDirectory}/vids";
    publicShare = "${storageDirectory}/sync";
  };

  # persist.storage.directories = [
  #   ".ssh"
  # ];

  persist.storage.files = [
    ".zsh_history"
    ".git-credentials"
  ];

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    "${config.home.storageDirectory}/src"
  ];

  # Learning about home-manager agenix
  age.secrets.my-secret.rekeyFile = ./secret.age;
  home.activation.secrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Symlink
    ln -sf ${config.age.secrets.my-secret.path} "${config.home.scratchDirectory}/my-secret-symlink.txt"

    # Real file copy
    cp -f ${config.age.secrets.my-secret.path} "${config.home.scratchDirectory}/my-secret-file.txt"
  '';
}
