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
    category = "key management";
    name = "sshed-build";
    help = "Generate ssh host keys from master key";
    command = "cd $PRJ_ROOT; sshed build";
  } {
    category = "key management";
    name = "sshed-send";
    help = "Send ssh host key generated from master key";
    command = ''cd $PRJ_ROOT; sshed send ''${1-} ''${2-}'';
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
    perSystem.self.sshed
    perSystem.self.ipaddr
    perSystem.self.hello
  ];

}
