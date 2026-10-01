_: {
  projectRootFile = "flake.nix";

  programs.alejandra = {
    enable = true;
    includes = ["*.nix" "**/*.nix"];
  };

  programs.prettier = {
    enable = true;
    includes = [
      "*.json"
      "**/*.json"
      "*.md"
      "**/*.md"
      "modules/home/desktop/hyprland/waybar/**/*.css"
    ];
  };

  programs.ruff-format = {
    enable = true;
    includes = ["*.py" "**/*.py"];
  };

  programs.shfmt = {
    enable = true;
    includes = [".envrc" "*.sh" "**/*.sh"];
  };

  programs.stylua = {
    enable = true;
    includes = [
      "modules/home/desktop/hyprland/lua/**/*.lua"
      "modules/home/desktop/hyprland/test.lua"
      "modules/home/desktop/default/options/desktop-theme/*.lua"
    ];
  };

  programs.yamlfmt = {
    enable = true;
    includes = ["modules/nixos/default/options/home-assistant/**/*.yaml"];
  };

  settings.global.excludes = [
    ".direnv/**"
    "result"
    "result/**"
    "scratch/**"
  ];
}
