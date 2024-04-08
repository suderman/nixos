{ pkgs, ... }: {

  # Aliases 
  home.shellAliases = with pkgs; rec {
    df = "df -h";
    du = "du -ch --summarize";
    fst = "sed -n '1p'";
    snd = "sed -n '2p'";
    ls = "lsd";
    la = "${ls} -A";
    l = "${ls} -Alho";
    map = "xargs -n1";
    maplines = "xargs -n1 -0";
    dmesg = "dmesg -H";
    rg = "rg --glob '!package-lock.json' --glob '!.git/*' --glob '!yarn.lock' --glob '!.yarn/*' --smart-case --hidden";
    grep = rg;
    tg = "tree-grepper";
    tree = "tree -a --dirsfirst -I .git";
    tl = "tldr";
    less = "less -R";

    # 5 second countdown until the clipboard gets typed out
    type-clipboard = ''
      sh -c 'sleep 5.0; ydotool type -- "$(wl-paste)"'
    '';

    # Force adoption of unifi devices
    adopt = ''
      for x in 1 2 3; do
        echo "10.1.0.$x set-inform http://10.1.0.4:8080/inform"
        ssh $USER@10.1.0.$x "/usr/bin/mca-cli-op set-inform http://10.1.0.4:8080/inform; exit"
      done
    '';

    # Bashly CLI
    bashly = "docker run --rm -it --user $(id -u):$(id -g) --volume \"$PWD:/app\" dannyben/bashly";

    j = "journalctl";
    s = "sudo systemctl";
    sz = "sudo sysz";

  };

}
