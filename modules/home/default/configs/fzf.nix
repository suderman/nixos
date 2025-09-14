# programs.fzf.enable = true;
{lib, ...}: {
  programs.fzf = {
    enable = lib.mkDefault true;
    enableZshIntegration = lib.mkDefault true;
  };

  home.sessionVariables = let
    rg = "rg --glob '!package-lock.json' --glob '!.git/*' --glob '!yarn.lock' --glob '!.yarn/*' --smart-case --hidden";
  in {
    FZF_DEFAULT_COMMAND = "command ${rg} --files --no-ignore-vcs";
    FZF_DEFAULT_OPTS = lib.mkDefault (builtins.toString [
      "--cycle"
      "--filepath-word"
      "--inline-info"
      "--reverse"
      "--pointer='*'"
      "--preview='head -100 {}'"
      "--preview-window=right:hidden"
      "--bind=ctrl-space:toggle-preview"
      "--color=light"
    ]);
  };
}
