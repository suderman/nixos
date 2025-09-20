{flake, ...}: {
  imports = [
    flake.inputs.agenix.homeManagerModules.default
    flake.inputs.agenix-rekey.homeManagerModules.default
    (flake + /secrets)
  ];
}
