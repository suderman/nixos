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
    pkgs.jq
    pkgs.iptables
    pkgs.netcat
    pkgs.openssh
    pkgs.passh
    pkgs.nix
    # pkgs.qemu (install separately on desktop)
  ];

  # Path to template files
  env.templates = ./templates;

  # Derivation index for the fleet root
  env.derivation_index = toString flake.derivationIndex;

  # Bash script
  text = builtins.readFile ./nixos.sh;
}
