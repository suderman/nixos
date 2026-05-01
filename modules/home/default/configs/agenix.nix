{flake, ...}: {
  imports = [
    flake.inputs.agenix.homeManagerModules.default
    flake.inputs.agenix-rekey.homeManagerModules.default
    (flake + /secrets)
  ];

  # Prevent unnecessary repeats
  systemd.user.services.agenix.Service.RemainAfterExit = true;
}
