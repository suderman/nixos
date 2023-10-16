# programs.git.enable = true;
{ config, lib, ... }: 

let
  cfg = config.programs.git;

in {

  config = lib.mkIf cfg.enable {

    programs.git = {
      ignores = [ "*~" "*.swp" ];
      extraConfig = {
        user = {
          name = "Buxel";
          email = "buxel.dev@gmail.com";
        };
        core = {
          autocrlf = "input";
          quotepath = "false";
        };
        init.defaultBranch = "main";
        push.default = "current";
        pull.rebase = "false";
        credential.helper = "store";
        color.ui = "auto";
        mergetool.keepBackup = "false";
        alias = {
          c = "commit -m";
          a = "add";
          di = "diff";
          dic = "diff --cached";
          pl = "pull";
          ps = "push";
          plre = "pull --rebase";
          st = "status";
          out = "log origin..HEAD";
          aa = "add --all";
          ap = "add --patch";
          ca = "commit --amend";
          ci = "commit -v";
          co = "checkout";
          create-branch = "!sh -c 'git push origin HEAD:refs/heads/$1 && git fetch origin && git branch --track $1 origin/$1 && cd . && git checkout $1' -";
          delete-branch = "!sh -c 'git push origin :refs/heads/$1 && git remote prune origin && git branch -D $1' -";
          merge-branch = "!git checkout master && git merge @{-1}";
          pr = "!hub pull-request";
          up = "!git fetch origin && git rebase origin/main";
          l = "log --graph --abbrev-commit --decorate --all --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'";
        };
      };
    };

  };

}
