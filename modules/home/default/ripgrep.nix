# programs.ripgrep.enable = true;
{pkgs, ...}: {
  programs.ripgrep = {
    package = pkgs.ripgrep-all;
    arguments = [
      "--max-columns=150"
      "--max-columns-preview"
      "--colors=line:style:bold" # pretty
      "--smart-case"
      "--hidden" # search hidden files/directories
      "--glob=!package-lock.json"
      "--glob=!node_modules/*"
      "--glob=!.git/*"
      "--glob=!yarn.lock"
      "--glob=!.yarn/*"
      "--glob=!dist/*"
      "--glob=!build/*"
      "--glob=!.cache/*"
      "--glob=!.vscode/*"
    ];
  };
}
