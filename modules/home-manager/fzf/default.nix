# programs.fzf.enable = true;
{ config, lib, ... }: 

let
  cfg = config.programs.fzf;

in {

  config = lib.mkIf cfg.enable {

    programs.fzf.enableZshIntegration = true;
    home.sessionVariables = {
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

  };

}
