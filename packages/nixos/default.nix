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
    pkgs.bat
    pkgs.git
    pkgs.gnugrep
    pkgs.gum
    pkgs.inetutils
    pkgs.iptables
    pkgs.netcat
    pkgs.openssh
    pkgs.passh
    # pkgs.qemu (install separately on desktops)
  ];

  # Path to template files
  env.templates = ./templates;

  # Derivation path for key
  env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";

  # Bash script
  text = builtins.readFile ./nixos.sh;
}
