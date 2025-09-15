{config, ...}: {
  # Create home folders (persisted)
  xdg.userDirs = let
    home = config.home.homeDirectory;
  in {
    desktop = "${home}/Personal/Action"; # persist
    download = "${home}/Downloads"; # persist
    documents = "${home}/Personal/Documents"; # persist
    music = "${home}/Personal/Music"; # persist
    pictures = "${home}/Personal/Pictures"; # persist
    videos = "${home}/Personal/Movies"; # persist
  };

  persist.storage.directories = [
    ".ssh"
    "Code"
    "Downloads"
    "Personal"
    "Work"
  ];

  persist.storage.files = [
    ".zsh_history"
    ".bash_history"
    ".git-credentials"
  ];
}
