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
  } {
    name ="DERIVATION_INDEX";
    value = toString flake.derivationIndex;
  }];

  # Base list of commands for devshell, plus extra
  commands = [{
    category = "key management";
    name = "import-id";
    help = "Generate age identity from QR code";
    command = readFile ./import-id.sh;
  } {
    category = "key management";
    name = "unlock-id";
    help = "Unlock age identity";
    command = readFile ./unlock-id.sh;
  } {
    category = "key management";
    name = "lock-id";
    help = "Lock age identity";
    command = readFile ./lock-id.sh;
  } {
    category = "development";
    name = "init";
    help = "Generate hosts, users and related files";
    command = readFile ./init.sh;
  } {
    category = "development";
    name = "b";
    help = "browse flake";
    command = "nix-inspect --path .";
  } {
    category = "development";
    name = "vm";
    help = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
    command = "nixos-rebuild --flake .#sim build-vm && ./result/bin/run-sim-vm";
  }];

  # Base list of packages for devshell, plus extra
  packages = [
    pkgs.eza
    pkgs.gh
    pkgs.git
    pkgs.gnumake
    pkgs.lazydocker
    pkgs.lazygit
    pkgs.nix-inspect
    pkgs.smenu
    pkgs.rage
    perSystem.agenix-rekey.default
    perSystem.self.qr
    perSystem.self.derive
    perSystem.self.sshed
    perSystem.self.ipaddr
    perSystem.self.hello
  ];

}
