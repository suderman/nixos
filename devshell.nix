{ flake, perSystem, pkgs, ... }: let 

  # inherit (flake) config;
  # inherit (flake.lib) mkShell;

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.age.text = ''
    [[ -e $HOME/.ssh/id_age ]] && cp -f $HOME/.ssh/id_age /tmp/id_age
    touch /tmp/id_age
    chmod 600 /tmp/id_age
  ''; 

  env = [];

  # Base list of commands for devshell, plus extra
  commands = [{
    name = "sim";
    help = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
    command = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
  }];

  # Base list of packages for devshell, plus extra
  packages = [
    pkgs.gh
    pkgs.git
    pkgs.gnumake
    pkgs.lazydocker
    pkgs.lazygit
    pkgs.smenu
    pkgs.rage
    perSystem.agenix-rekey.default
    # perSystem.self.deterministic-keygen
    perSystem.self.seed-to-ssh
  ];

}
