{
  config,
  perSystem,
  ...
}: {
  home.packages = [
    perSystem.neovim.default
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
    diff = "nvim -d";
  };

  # OPENROUTER_API_KEY=xxxxxx
  # age.secrets.openrouter.rekeyFile = ./openrouter.age;
  # EnvironmentFile = [config.age.secrets.openrouter.path];

  # settings.persist.home.directories = [
  #   ".local/share/nvim"
  #   ".local/state/nvim"
  # ];
  # (lib.mkIf config.settings.terminal.emulator.enable {
  #   xdg.desktopEntries.nvim = {
  #     name = "Neovim";
  #     genericName = "Text Editor";
  #     icon = "nvim";
  #     exec = "${config.settings.terminal.emulator.exec} nvim %f";
  #   };
  # })
}
