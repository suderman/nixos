{ self, super, ... }: {

  # Personal scripts
  yo = self.callPackage ./yo.nix { };

  # Override existing packages
  # chromium = super.chromium.override {
  #   commandLineArgs = "--proxy-server='https=127.0.0.1:3128;http=127.0.0.1:3128'";
  # };

}
