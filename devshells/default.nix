{
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) toString readFile;
in
  perSystem.devshell.mkShell {
    # Set name of devshell from config
    devshell.name = "suderman/nixos";

    # Startup script of devshell, plus extra
    devshell.startup.nixos.text = "";

    env = [
      {
        name = "LIB";
        value = toString flake.lib.bash;
      }
      {
        name = "DERIVATION_INDEX";
        value = toString flake.derivationIndex;
      }
    ];

    # Base list of commands for devshell, plus extra
    commands = [
      {
        category = "development";
        name = "agenix";
        help = "Manage secrets and identity";
        package = perSystem.self.agenix;
      }
      {
        category = "development";
        name = "init";
        help = "Generate hosts, users and related files";
        command = readFile ./init.sh;
      }
      {
        category = "development";
        name = "browse";
        help = "Browse flake";
        command = "nix-inspect --path .";
      }
      {
        category = "virtual machine";
        name = "sim";
        help = "boot vm";
        package = perSystem.self.sim;
      }
      {
        category = "virtual machine";
        name = "iso";
        help = "build iso";
        package = perSystem.self.iso;
      }
    ];

    # Base list of packages for devshell, plus extra
    packages = [
      pkgs.age
      pkgs.alejandra
      pkgs.eza
      pkgs.gh
      pkgs.git
      pkgs.gnumake
      pkgs.lazydocker
      pkgs.lazygit
      pkgs.nix-inspect
      pkgs.nixos-anywhere
      pkgs.openssl
      pkgs.smenu
      perSystem.self.agenix
      perSystem.self.derive
      perSystem.self.sshed
      perSystem.self.ipaddr
      perSystem.self.hello
    ];
  }
