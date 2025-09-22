{
  config,
  lib,
  ...
}: {
  xdg.userDirs = with config.home; {
    download = "${scratchDirectory}";
    desktop = "${storageDirectory}/Action";
    documents = "${storageDirectory}/Documents";
    music = "${storageDirectory}/Music";
    pictures = "${storageDirectory}/Pictures";
    videos = "${storageDirectory}/Movies";
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
  age.secrets.mysecret.rekeyFile = ./secret.age;
  home.activation.secrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Symlink
    ln -sf ${config.age.secrets.mysecret.path} "${config.home.homeDirectory}/my-link.txt"

    # Real file copy
    cp -f ${config.age.secrets.mysecret.path} "${config.home.homeDirectory}/my-file.txt"
  '';
}
