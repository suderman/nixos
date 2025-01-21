{ pkgs, ... }: {

  # Aliases 
  home.shellAliases = with pkgs; rec {
    fst = "sed -n '1p'";
    snd = "sed -n '2p'";
    dmesg = "dmesg -H";
    tg = "tree-grepper";
    tree = "tree -a --dirsfirst -I .git";

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
