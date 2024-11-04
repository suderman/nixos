{ pkgs, ... }: {

  # Aliases 
  home.shellAliases = with pkgs; rec {
    df = "df -h";
    du = "du -ch --summarize";
    ls = "lsd";
    la = "${ls} -A";
    l = "${ls} -Alh";
    map = "xargs -n1";
    maplines = "xargs -n1 -0";
    grep = "rg";
    tl = "tldr";
  };

  programs.btop = {
    enable = true;
    package = pkgs.btop.overrideAttrs (prev: rec {
      cmakeFlags = (prev.cmakeFlags or []) ++ [
        # "-DBTOP_RSMI_STATIC=ON"
        # "-DBTOP_GPU=ON"
        "GPU_SUPPORT=true"
      ];
    });
  };

  programs.zoxide.enable = true;

  programs.less.enable = true;
  programs.lesspipe.enable = true;

  programs.ripgrep = {
    enable = true;
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
