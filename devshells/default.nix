{ flake, perSystem, pkgs, ... }: let 

  inherit (builtins) toString readFile;
  inherit (flake.lib) ls;

  vm = toString [
    "qemu-system-x86_64"
    "-enable-kvm"
    "-m 4096"
    "-cpu host"
    "-nic user,hostfwd=tcp::2222-:22"
    # "-netdev bridge,id=net0,br=br0"
    # "-device virtio-net-pci,netdev=net0"
    "-drive file=vm.img,format=qcow2"
  ];

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
    category = "vm";
    name = "vm-iso";
    help = "create installer iso";
    command = "nix build .#nixosConfigurations.iso.config.system.build.isoImage";
  } {
    category = "vm";
    name = "vm-drive";
    help = "create vm drive";
    command = "qemu-img create -f qcow2 vm.img 20G";
  } {
    category = "vm";
    name = "vm-install";
    help = "boot vm with iso";
    command = "${vm} -cdrom result/iso/nixos*.iso -boot d";
  } {
    category = "vm";
    name = "vm";
    help = "run vm";
    command = vm;
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
    pkgs.openssl
    pkgs.smenu
    pkgs.rage
    pkgs.qemu
    pkgs.nixos-anywhere
    perSystem.disko.default
    perSystem.agenix-rekey.default
    perSystem.self.qr
    perSystem.self.derive
    perSystem.self.sshed
    perSystem.self.ipaddr
    perSystem.self.hello
  ];

}
