# programs.fzf.enable = true;
{ config, lib, ... }: with lib; {

  config = mkIf config.programs.fzf.enable {

    programs.fzf.enableZshIntegration = true;
    home.sessionVariables = let
      rg = "rg --glob '!package-lock.json' --glob '!.git/*' --glob '!yarn.lock' --glob '!.yarn/*' --smart-case --hidden";
    in {
      FZF_DEFAULT_COMMAND = "command ${rg} --files --no-ignore-vcs";
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
