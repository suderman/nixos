{ flake, perSystem, pkgs, ... }: let 

  # inherit (flake) config;
  inherit (flake.lib) helpers;

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.nixos.text = ''
  ''; 

  env = [];

  # Base list of commands for devshell, plus extra
  commands = [{
    category = "virtual machine";
    name = "sim";
    help = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
    command = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
  } {
    category = "age identity";
    name = "import-id";
    help = "Generate age identity from QR code";
    command = ''
      source ${helpers} && cd $(flake)
      if has id.age; then
        [[ ! -s id.age ]] && rm -f id.age || error "$(pwd)/id.age already exists"
      fi
      seed="$(qr)"
      empty "$seed" && error "Failed to read QR code"
      echo "$seed" | to-age | rage -ep > id.age
      info "QR code imported as encrypted age identity: $(pwd)/id.age"
      echo "$seed" | rage -er "$(echo "$seed" | to-age | to-public)" > seed.age
      git add seed.age
      info "QR code imported as encrypted seed: $(pwd)/seed.age"
      echo "$seed" | to-age | unlock-id
    '';
  } {
    category = "age identity";
    name = "unlock-id";
    help = "Unlock age identity";
    command = ''
      source ${helpers} && cd $(flake)
      id="$(input)"
      if empty "$id"; then
        hasnt id.age && error "$(pwd)/id.age missing"
        id="$(cat id.age | rage -d)"
        empty "$id" && error "Failed to unlock age identity"
      fi
      has /tmp/id_age && mv /tmp/id_age /tmp/id_age_prev
      touch /tmp/id_age_prev
      echo "$id" > /tmp/id_age
      chmod 600 /tmp/id_age /tmp/id_age_prev
      info "Age identity unlocked"
    '';
  } {
    category = "age identity";
    name = "lock-id";
    help = "Lock age identity";
    command = ''
      source ${helpers} && cd $(flake)
      rm -f /tmp/id_age /tmp/id_age_prev
      info "Age identity locked"
    '';
  # } {
  #   category = "misc";
  #   name = "qr-to-ssh";
  #   help = "Generate ssh key pair from QR code";
  #   command = let key = "~/.ssh/id_ed25519"; in ''
  #     source ${helpers} && cd $(flake)
  #     has ${key} && error "${key} already exists"
  #     qr | to-ssh > ${key}
  #     cat ${key} | to-public > ${key}.pub
  #   '';
  } {
    category = "ssh host keys";
    name = "ssh-keysgen";
    help = "Generate ssh host keys from seed";
    command = ''
      source ${helpers} && cd $(flake)
      hasnt seed.age && error "$(pwd)/seed.age missing"
      hasnt /tmp/id_age && error "Age identity locked"
      for host in $(ls hosts); do
        echo "$(cat seed.age | rage -di /tmp/id_age | to-hex "$host" | to-ssh | to-public) @$host" > hosts/$host/ssh.pub
        git add hosts/$host/ssh.pub
        info "Public ssh host key generated: $(pwd)/hosts/$host/ssh.pub"
      done
    '';
  } {
    category = "ssh host keys";
    name = "ssh-keysend";
    help = "Send ssh host key generated from seed";
    command = ''
      source ${helpers} && cd $(flake)
      ip="''${1-}"
      empty "$ip" && error "Missing destination IP address"
      hasnt seed.age && error "$(pwd)/seed.age missing"
      hasnt /tmp/id_age && error "Age identity locked"
      cat seed.age | rage -di /tmp/id_age | to-hex "$(ls hosts | smenu)" | to-ssh | nc -N $ip 12345
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
