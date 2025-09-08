{
  pkgs,
  perSystem,
  ...
}: let
  inherit (perSystem.self) mkScript;
in {
  home.packages = with pkgs; [
    yo # example script
    perSystem.self.fetchgithub # fetch hash from repo
    perSystem.self.shizuku # connect android to pc and run
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
