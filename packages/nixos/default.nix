{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  name = "nixos";
  path = [
    perSystem.self.agenix
    perSystem.self.derive
    perSystem.self.ipaddr
    pkgs.age
    pkgs.alejandra
    pkgs.attic-client
    pkgs.bat
    pkgs.git
    pkgs.gnugrep
    pkgs.gum
    pkgs.inetutils
    pkgs.iptables
    pkgs.netcat
    pkgs.openssh
    pkgs.passh
    pkgs.python3
    pkgs.nix
    # pkgs.qemu (install separately on desktop)
  ];

  # Path to template files
  env.templates = ./templates;

  # Derivation path for key
  env.derivation_index = toString flake.derivationIndex;
  env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";
  env.identity_rotation_directory = ../../secrets/rotation;
  env.identity_rotation_system = pkgs.stdenv.hostPlatform.system;

  # Bash script
  text = builtins.readFile ./nixos.sh;
}
