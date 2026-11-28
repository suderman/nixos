{...}: let
  caches = [
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
    # kevinpita/herdr-nix
    {
      url = "https://kevinpita.cachix.org?priority=50";
      key = "kevinpita.cachix.org-1:Cu9UtCDSfDq3/WDnI7N1N/LzAh90SPS+1R+nWao/hz0=";
    }
    # mulatta
    {
      url = "https://cache.mulatta.io?priority=50";
      key = "cache.mulatta.io-1:DrV+Oy2azNyVKM7ihhD1QoOetRUnW+1G6RWToUpSO4U=";
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
