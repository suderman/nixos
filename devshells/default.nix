{ flake, perSystem, pkgs, ... }: let 

  inherit (builtins) toString readFile;
  inherit (flake.lib) ls;

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.nixos.text = ''
  ''; 

  env = [{
    name = "LIB";
    value = toString flake.lib.bash;
  }];

  # Base list of commands for devshell, plus extra
  commands = [{
    category = "age identity";
    name = "import-id";
    help = "Generate age identity from QR code";
    command = readFile ./import-id.sh;
  } {
    category = "age identity";
    name = "unlock-id";
    help = "Unlock age identity";
    command = readFile ./unlock-id.sh;
  } {
    category = "age identity";
    name = "lock-id";
    help = "Lock age identity";
    command = readFile ./lock-id.sh;
  } {
    category = "ssh host keys";
    name = "ssh-keysgen";
    help = "Generate ssh host keys from seed";
    command = readFile ./ssh-keysgen.sh;
  } {
    category = "ssh host keys";
    name = "ssh-keysend";
    help = "Send ssh host key generated from seed";
    command = readFile ./ssh-keysend.sh;
  } {
    category = "virtual machine";
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
    perSystem.self.qr
    perSystem.self.derive
    # perSystem.self.to
    # perSystem.self.to-age
    # perSystem.self.to-hex
    # perSystem.self.to-public
    # perSystem.self.to-ssh
    perSystem.self.hello
  ];

}
