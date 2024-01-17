{ lib, packages ? [], betaPackages ? [], ... }: {

  # Weekly updates
  update.auto.enable = true;

  # Stable and beta repos
  remotes = [
    { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    { name = "flathub-beta"; location = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
  ];

  # Combine lists into one for services.flatpak.packages
  packages = (
    map ( appId: { inherit appId; origin = "flathub"; } ) packages
  ) ++ (
    map ( appId: { inherit appId; origin = "flathub-beta"; } ) betaPackages
  );

}
