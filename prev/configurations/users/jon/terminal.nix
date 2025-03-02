{ config, lib, pkgs, profiles, ... }: let

  inherit (lib) ls mkShellScript;

  # example bash script
  coffee = mkShellScript { name = "coffee"; text = ./bin/coffee.sh; };

in {

  home.packages = with pkgs; [ 
    yo # example script
    bin-foo bin-bar # more example scripts
    fetchgithub # fetch hash from repo
    lame # mp3 codec
    shizuku # connect android to pc and run
    imagemagick # animate compare composite conjure convert display identify import magick magick-script mogrify montage stream
  ];

  # Aliases 
  home.shellAliases = {

    neofetch = "fastfetch";

    # 5 second countdown until the clipboard gets typed out
    type-clipboard = ''
      sh -c 'sleep 5.0; ydotool type -- "$(wl-paste)"'
    '';

    # Force adoption of unifi devices
    unifi-adopt = ''
      for x in 1 2 3; do
        echo "10.1.0.$x set-inform http://10.1.0.4:8080/inform"
        ssh $USER@10.1.0.$x "/usr/bin/mca-cli-op set-inform http://10.1.0.4:8080/inform; exit"
      done
    '';

    # Bashly CLI
    bashly = "docker run --rm -it --user $(id -u):$(id -g) --volume \"$PWD:/app\" dannyben/bashly";

    # manage systemd units
    isd = "nix run github:isd-project/isd"; 

  };

}
