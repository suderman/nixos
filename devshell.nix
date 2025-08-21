{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.devshell.mkShell {
  # Set name of devshell from config
  devshell.name = "suderman/nixos";

  # Startup script of devshell, plus extra
  devshell.startup.nixos.text = "";

  env = [
    {
      name = "DERIVATION_INDEX";
      value = toString flake.derivationIndex;
    }
  ];

  # Base list of commands for devshell, plus extra
  commands = [
    {
      category = "development";
      name = "nixos";
      help = "Deploy hosts and generate files";
      package = perSystem.self.default;
    }
    {
      category = "development";
      name = "agenix";
      help = "Manage secrets and identity";
      package = perSystem.self.agenix;
    }
    {
      category = "development";
      name = "browse";
      help = "Browse flake";
      command = "nix-inspect --path .";
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
    (pkgs.python3.withPackages (ps: [ps.cryptography]))
    perSystem.self.agenix
    perSystem.self.default
    perSystem.self.derive
    perSystem.self.ipaddr
    perSystem.self.sshed
  ];
}
