{
  uid = 1000;
  description = "Jon Suderman";
  # June reaches her workers in my accounts from bot.
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub ../june/id_ed25519.pub];
  extraGroups = ["wheel"]; # sudo
}
