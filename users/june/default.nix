{
  # Agent accounts start at 1100, leaving 1002-1099 for family.
  uid = 1100;
  description = "June";
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub ../jon/id_ed25519.pub];
}
