{ flake, perSystem, pkgs, ... }: let 

  # inherit (flake) config;
  inherit (flake.lib) helpers;

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.age.text = ''
    # [[ -e id_age ]] && cp -f id_age /tmp/id_age
    # touch /tmp/id_age
    # chmod 600 /tmp/id_age
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
    command = ''
      source ${helpers}
      has id_age.age && error "$(pwd)/id_age.age already exists"
      id="$(qr | to-age)"
      empty "$id" && error "Failed to read QR code"
      echo "$id" | rage -ep > id_age.age
      info "QR code imported as encrypted age identity: $(pwd)/id_age.age"
      echo "$id" > /tmp/id_age
      chmod 600 /tmp/id_age
      info "Age identity unlocked"
    '';
  } {
    name = "unlock";
    help = "Unlock age identity";
    command = ''
      source ${helpers}
      hasnt id_age.age && error "$(pwd)/id_age.age missing"
      id="$(cat id_age.age | rage -d)"
      empty "$id" && error "Failed to unlock age identity"
      echo "$id" > /tmp/id_age
      chmod 600 /tmp/id_age
      info "Age identity unlocked"
    '';
  } {
    name = "lock";
    help = "Lock age identity";
    command = ''
      source ${helpers}
      rm -f /tmp/id_age
      info "Age identity locked"
    '';
  } {
    name = "qr-to-ssh";
    help = "Generate ssh key pair from QR code";
    command = let key = "~/.ssh/id_ed25519"; in ''
      source ${helpers}
      has ${key} && error "${key} already exists"
      qr | to-ssh > ${key}
      cat ${key} | to-public > ${key}.pub
    '';
  } {
    name = "gen-seed";
    help = "Generate seed from id_age";
    command = ''
      source ${helpers}
      hasnt /tmp/id_age && error "Age identity locked"
      seed="$(cat /tmp/id_age | to-hex seed)"
      empty "$seed" && error "Failed to generate seed"
      echo "$seed" | rage -ei /tmp/id_age > seed.age
      info "Encrypted seed generated: $(pwd)/seed.age"
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
