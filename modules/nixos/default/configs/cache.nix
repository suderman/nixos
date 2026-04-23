{...}: let
  caches = [
    # primary
    {
      url = "https://cache.nixos.org?priority=40";
      key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    }
    # community
    {
      url = "https://nix-community.cachix.org?priority=50";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    }
    # numtide
    {
      url = "https://cache.numtide.com?priority=50";
      key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
    }
    # personal
    {
      url = "https://attic.kit/main?priority=60";
      key = "main:h4StHo979ngwL9amukioJJO+TJIb3Dbe7+HNSS/umwA=";
    }
  ];
in {
  # binary cache
  nix.settings = {
    substituters = map (c: c.url) caches;
    trusted-public-keys = map (c: c.key) caches;
  };
}
