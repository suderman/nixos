{ inputs, config, lib, pkgs, user, ... }: 

with builtins;

let
  inherit (pkgs) stdenv; 

in {

  imports = [ ../. ];

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  home.username = user;
  home.homeDirectory = "/${if (stdenv.isLinux) then "home" else "Users"}/${user}";

  # ---------------------------------------------------------------------------
  # Home Shell
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    bat 
    cowsay
    exa
    killall
    lf 
    lsd
    micro
    mosh
    nano
    ripgrep
    wget
    python39
    python39Packages.pip
    python39Packages.virtualenv
    nodejs
    cargo
  ];

  home.shellAliases = with pkgs; rec {
    cp = "cp -i";
    rm = "rm -I";
    df = "df -h";
    diff = "diff --color=auto";
    du = "du -ch --summarize";
    fst = "sed -n '1p'";
    snd = "sed -n '2p'";
    ls = "LC_ALL=C ${coreutils}/bin/ls --color=auto --group-directories-first";
    la = "${ls} -A";
    l = "${ls} -Alho";
    map = "xargs -n1";
    maplines = "xargs -n1 -0";
    mongo = "mongo --norc";
    dmesg = "dmesg -H";
    cloc = "tokei";
    rg = "rg --glob '!package-lock.json' --glob '!.git/*' --glob '!yarn.lock' --glob '!.yarn/*' --smart-case --hidden";
    grep = rg;
    tg = "tree-grepper";
    tree = "tree -a --dirsfirst -I .git";
    tl = "tldr";
    less = "less -R";
    type-clipboard = ''
      sh -c 'sudo sleep 5.0; sudo ydotool type -- "$(wl-paste)"'
    '';
  };

  programs.fzf.enable = true;
  programs.neovim.enable = true;

  # Add support for ~/.local/bin
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ---------------------------------------------------------------------------
  # Home Settings
  # ---------------------------------------------------------------------------

  # # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
  # home.activation = {
  #   linkDesktopApplications = {
  #     after = [ "writeBoundary" "createXdgUserDirectories" ];
  #     before = [ ];
  #     data = ''
  #       rm -rf ${config.xdg.dataHome}/"applications/home-manager"
  #       mkdir -p ${config.xdg.dataHome}/"applications/home-manager"
  #       cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/"applications/home-manager/"
  #     '';
  #   };
  # };

  # Enable home-manager, git & zsh
  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.zsh.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Enable flakes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";

}
