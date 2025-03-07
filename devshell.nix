{ flake, perSystem, pkgs, ... }: let 

  # inherit (flake) config;
  # inherit (flake.lib) mkShell;

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.age.text = ''
    [[ -e id_age ]] && cp -f id_age /tmp/id_age
    touch /tmp/id_age
    chmod 600 /tmp/id_age
  ''; 

  env = [];

  # Base list of commands for devshell, plus extra
  commands = [{
    name = "sim";
    help = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
    command = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
  } {
    name = "qr-to-age";
    help = "Generate age identity from QR code";
    command = let key = "id_age"; in ''
      [[ -e "$(pwd)/${key}" ]] && echo "$(pwd)/${key} already exists" && exit
      qr | to-age > ${key}
      cp -f ${key} /tmp/${key}
      chmod 600 /tmp/${key}
    '';
  } {
    name = "qr-to-ssh";
    help = "Generate ssh key pair from QR code";
    command = let key = "~/.ssh/id_ed25519"; in ''
      [[ -e ${key} ]] && echo "${key} already exists" && exit
      qr | to-ssh > ${key}
      cat ${key} | to-public > ${key}.pub
    '';
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
    perSystem.self.qr
    perSystem.self.to-age
    perSystem.self.to-hex
    perSystem.self.to-public
    perSystem.self.to-ssh
  ];

}
