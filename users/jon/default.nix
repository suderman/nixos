{
  uid = 1000;
  description = "Jon Suderman";
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];
  extraGroups = ["wheel"]; # sudo
}
