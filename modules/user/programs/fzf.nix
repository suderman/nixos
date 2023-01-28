{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.fzf;

# in with pkgs.lib; {
in {

  # programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  home.sessionVariables = lib.mkIf cfg.enable {
    FZF_DEFAULT_COMMAND = "command ${config.home.shellAliases.rg} --files --no-ignore-vcs";
    FZF_DEFAULT_OPTS = builtins.toString [
      "--cycle"
      "--filepath-word"
      "--inline-info"
      "--reverse"
      "--pointer='*'"
      "--preview='head -100 {}'"
      "--preview-window=right:hidden"
      "--bind=ctrl-space:toggle-preview"
      "--color=light"
    ];
  };

}
