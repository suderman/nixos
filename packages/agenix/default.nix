{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  name = "agenix"; # Use same name as existing agenix command we're extending
  path = [
    perSystem.agenix-rekey.default # agenix command to extend
    perSystem.self.derive
    perSystem.self.qr
    pkgs.age
    pkgs.git
    pkgs.gum
  ];

  # Derivation index for hex
  env.derivation_index = toString flake.derivationIndex;

  # Bash script
  text = builtins.readFile ./agenix.sh;
}
